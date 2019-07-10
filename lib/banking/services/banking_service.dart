import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/proxy_account_store.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/localizations.dart';
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

  String _bankId(String proxyUniverse) {
    if (proxyUniverse == ProxyUniverse.PRODUCTION) {
      return "wallet";
    } else {
      return "test-wallet";
    }
  }

  Future<ProxyAccountEntity> createProxyWallet({
    @required ProxyLocalizations localizations,
    @required ProxyId ownerProxyId,
    @required String proxyUniverse,
    @required String currency,
  }) async {
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(ownerProxyId);
    ProxyWalletCreationRequest request = ProxyWalletCreationRequest(
      requestId: uuidFactory.v4(),
      proxyUniverse: proxyUniverse,
      proxyId: proxyKey.id,
      bankId: ProxyId(_bankId(proxyUniverse)),
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
    return _saveAccount(localizations, ownerProxyId, signedResponse);
  }

  ProxyAccountEntity _saveAccount(
    ProxyLocalizations localizations,
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
