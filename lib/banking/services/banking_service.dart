import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/bank_store.dart';
import 'package:proxy_flutter/banking/db/proxy_account_store.dart';
import 'package:proxy_flutter/banking/model/bank_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class BankingService with ProxyUtils, HttpClientUtils, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyAccountStore _proxyAccountStore;
  final ProxyKeyStore _proxyKeyStore;

  BankingService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _proxyKeyStore = ProxyKeyStore(appConfiguration),
        _proxyAccountStore = ProxyAccountStore(appConfiguration) {
    assert(appConfiguration != null);
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<BankEntity> _fetchDefaultBank({String proxyUniverse}) {
    proxyUniverse = proxyUniverse ?? appConfiguration.proxyUniverse;
    String bankId = proxyUniverse == ProxyUniverse.PRODUCTION ? "wallet" : "test-wallet";
    return BankStore().fetchBank(
      proxyUniverse: proxyUniverse,
      bankId: bankId,
    );
  }

  Future<Set<String>> supportedCurrenciesForDefaultBank({String proxyUniverse}) async {
    print("supportedCurrenciesForDefaultBank(proxyUniverse: $proxyUniverse)");
    BankEntity bank = await _fetchDefaultBank(proxyUniverse: proxyUniverse);
    return bank.supportedCurrencies;
  }

  Future<Set<String>> supportedCurrenciesForBank({
    String proxyUniverse,
    @required ProxyId bankProxyId,
  }) async {
    BankEntity bank = await BankStore().fetchBank(
      proxyUniverse: proxyUniverse ?? appConfiguration.proxyUniverse,
      bankProxyId: bankProxyId,
    );
    return bank.supportedCurrencies;
  }

  Future<ProxyAccountEntity> fetchOrCreateProxyWallet({
    @required ProxyId ownerProxyId,
    @required String proxyUniverse,
    @required String currency,
  }) async {
    List<ProxyAccountEntity> existing = await _proxyAccountStore.fetchActiveAccounts(
      masterProxyId: ownerProxyId,
      currency: currency,
      proxyUniverse: proxyUniverse,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }
    return createProxyWallet(
      ownerProxyId: ownerProxyId,
      proxyUniverse: proxyUniverse,
      currency: currency,
    );
  }

  Future<ProxyAccountEntity> createProxyWallet({
    @required ProxyId ownerProxyId,
    @required String proxyUniverse,
    @required String currency,
  }) async {
    BankEntity bank = await _fetchDefaultBank(proxyUniverse: proxyUniverse);
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(ownerProxyId);
    ProxyWalletCreationRequest request = ProxyWalletCreationRequest(
      requestId: uuidFactory.v4(),
      proxyUniverse: proxyUniverse,
      proxyId: proxyKey.id,
      bankId: bank.bankProxyId,
      currency: currency,
    );
    SignedMessage<ProxyWalletCreationRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      body: signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<ProxyWalletCreationResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, ProxyWalletCreationResponse.fromJson);
    return _saveAccount(ownerProxyId, signedResponse);
  }

  ProxyAccountEntity _saveAccount(
    ProxyId ownerProxyId,
    SignedMessage<ProxyWalletCreationResponse> signedResponse,
  ) {
    ProxyWalletCreationResponse response = signedResponse.message;
    ProxyAccount proxyAccount = response.proxyAccount.message;
    ProxyAccountId proxyAccountId = proxyAccount.proxyAccountId;
    ProxyAccountEntity proxyAccountEntity = ProxyAccountEntity(
      accountId: proxyAccountId,
      accountName: "",
      bankName: proxyAccount.bankId,
      balance: Amount(
        currency: proxyAccount.currency,
        value: 0,
      ),
      ownerProxyId: ownerProxyId,
      signedProxyAccount: response.proxyAccount,
      active: true,
    );
    _proxyAccountStore.saveAccount(proxyAccountEntity);
    return proxyAccountEntity;
  }

  Future<void> refreshAccount(ProxyAccountId accountId) async {
    print('Refreshing $accountId');
    ProxyAccountEntity proxyAccount = await _proxyAccountStore.fetchAccount(accountId);
    if (proxyAccount == null) {
      // This can happen when alert reaches earlier than API response, or account is removed.
      print("Account $proxyAccount not found");
      return null;
    }
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(proxyAccount.ownerProxyId);
    AccountBalanceRequest request = AccountBalanceRequest(
      requestId: uuidFactory.v4(),
      proxyAccount: proxyAccount.signedProxyAccount,
    );
    SignedMessage<AccountBalanceRequest> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      body: signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<AccountBalanceResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, AccountBalanceResponse.fromJson);
    if (signedResponse.message.balance != proxyAccount.balance) {
      print("Account $accountId has balance => ${proxyAccount.balance}");
      _proxyAccountStore.saveAccount(proxyAccount.copy(balance: signedResponse.message.balance));
    }
  }
}
