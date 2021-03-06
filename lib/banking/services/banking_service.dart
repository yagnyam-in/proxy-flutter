import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/bank_store.dart';
import 'package:promo/banking/db/proxy_account_store.dart';
import 'package:promo/banking/model/banking_service_provider_entity.dart';
import 'package:promo/banking/model/proxy_account_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/services/service_helper.dart';
import 'package:promo/url_config.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class BankingService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyAccountStore _proxyAccountStore;

  BankingService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? HttpClientUtils.httpClient(),
        _proxyAccountStore = ProxyAccountStore(appConfiguration) {
    assert(appConfiguration != null);
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<BankingServiceProviderEntity> _fetchDefaultWalletServiceProvider({String proxyUniverse}) {
    proxyUniverse = proxyUniverse ?? appConfiguration.proxyUniverse;
    String bankId = proxyUniverse == ProxyUniverse.PRODUCTION ? "wallet" : "test-wallet";
    return BankStore(appConfiguration).fetchBank(
      bankId: bankId,
    );
  }

  Future<Set<String>> supportedCurrenciesForDefaultBank({String proxyUniverse}) async {
    print("supportedCurrenciesForDefaultBank(proxyUniverse: $proxyUniverse)");
    BankingServiceProviderEntity bank = await _fetchDefaultWalletServiceProvider(proxyUniverse: proxyUniverse);
    return bank.supportedCurrencies;
  }

  Future<Set<String>> supportedCurrenciesForBank({
    String proxyUniverse,
    @required ProxyId bankProxyId,
  }) async {
    BankingServiceProviderEntity bank = await BankStore(appConfiguration).fetchBank(
      bankProxyId: bankProxyId,
    );
    return bank.supportedCurrencies;
  }

  Future<ProxyAccountEntity> fetchOrCreateProxyWallet({
    @required ProxyId ownerProxyId,
    @required String bankId,
    @required String proxyUniverse,
    @required String currency,
  }) async {
    List<ProxyAccountEntity> existing = await _proxyAccountStore.fetchActiveAccounts(
      bankId: bankId,
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
    BankingServiceProviderEntity bank = await _fetchDefaultWalletServiceProvider(proxyUniverse: proxyUniverse);
    ProxyWalletCreationRequest request = ProxyWalletCreationRequest(
      requestId: uuidFactory.v4(),
      proxyUniverse: proxyUniverse,
      ownerProxyId: ownerProxyId,
      bankProxyId: bank.bankProxyId,
      currency: currency,
    );
    final signedRequest = await signMessage(
      signer: ownerProxyId,
      request: request,
    );
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: ProxyWalletCreationResponse.fromJson,
    );
    return _saveAccount(ownerProxyId, signedResponse, bank);
  }

  Future<ProxyAccountEntity> _saveAccount(
    ProxyId ownerProxyId,
    SignedMessage<ProxyWalletCreationResponse> signedResponse,
    BankingServiceProviderEntity bank,
  ) {
    ProxyWalletCreationResponse response = signedResponse.message;
    ProxyAccount proxyAccount = response.proxyAccount.message;
    ProxyAccountId proxyAccountId = proxyAccount.proxyAccountId;
    ProxyAccountEntity proxyAccountEntity = ProxyAccountEntity(
      proxyAccountId: proxyAccountId,
      proxyUniverse: bank.proxyUniverse,
      accountName: "",
      bankName: bank.bankName,
      balance: Amount(
        currency: proxyAccount.currency,
        value: 0,
      ),
      ownerProxyId: ownerProxyId,
      signedProxyAccount: response.proxyAccount,
      active: true,
    );
    return _proxyAccountStore.save(proxyAccountEntity);
  }

  Future<void> _refreshAccountById(ProxyAccountId accountId) async {
    print('Refreshing $accountId');
    ProxyAccountEntity proxyAccount = await _proxyAccountStore.fetchAccount(proxyAccountId: accountId);
    if (proxyAccount == null) {
      // This can happen when alert reaches earlier than API response, or account is removed.
      print("Account $proxyAccount not found");
      return null;
    }
    return refreshAccount(proxyAccount);
  }

  Future<void> refreshAccount(ProxyAccountEntity proxyAccount) async {
    AccountBalanceRequest request = AccountBalanceRequest(
      requestId: uuidFactory.v4(),
      proxyAccount: proxyAccount.signedProxyAccount,
    );
    final signedRequest = await signMessage(
      signer: proxyAccount.ownerProxyId,
      request: request,
    );
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: AccountBalanceResponse.fromJson,
    );
    if (signedResponse.message.balance != proxyAccount.balance) {
      await _proxyAccountStore.save(proxyAccount.copy(balance: signedResponse.message.balance));
    }
  }

  Future<void> processAccountUpdatedAlert(AccountUpdatedAlert alert) {
    return _refreshAccountById(alert.proxyAccountId);
  }

  Future<void> processAccountUpdatedLiteAlert(AccountUpdatedLiteAlert alert) {
    return _refreshAccountById(alert.proxyAccountId);
  }
}
