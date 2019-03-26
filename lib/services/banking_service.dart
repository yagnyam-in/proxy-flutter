import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class BankingService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyAccountRepo proxyAccountRepo;
  final ProxyKeyRepo proxyKeyRepo;

  BankingService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyAccountRepo,
    @required this.proxyKeyRepo,
  })
      : proxyBankingUrl = proxyBankingUrl ?? "https://proxy-banking.appspot.com/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<ProxyAccountEntity> createProxyWallet(ProxyId ownerProxyId, String currency) async {
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(ownerProxyId);
    ProxyWalletCreationRequest request = ProxyWalletCreationRequest(
      requestId: uuidFactory.v4(),
      proxyId: proxyKey.id,
      bankId: ProxyId("wallet"),
      currency: currency,
    );
    SignedMessage<ProxyWalletCreationRequest> signedRequest =
    await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<ProxyWalletCreationResponse> signedResponse =
    await messageFactory.buildAndVerifySignedMessage(jsonResponse, ProxyWalletCreationResponse.fromJson);
    return _saveAccount(ownerProxyId, signedResponse);
  }

  Future<String> depositLink(ProxyId ownerProxyId, Amount amount, {ProxyAccountEntity proxyAccount}) async {
    if (proxyAccount == null) {
      proxyAccount = await createProxyWallet(ownerProxyId, amount.currency);
    }
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(ownerProxyId);
    DepositLinkRequest request = DepositLinkRequest(
      requestId: uuidFactory.v4(),
      proxyAccount: proxyAccount.signedProxyAccount,
      accountName: proxyAccount.validAccountName,
      amount: amount,
    );
    SignedMessage<DepositLinkRequest> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositLinkResponse> signedResponse =
    await messageFactory.buildAndVerifySignedMessage(jsonResponse, DepositLinkResponse.fromJson);
    return signedResponse.message.depositLink;
  }


  ProxyAccountEntity _saveAccount(ProxyId ownerProxyId, SignedMessage<ProxyWalletCreationResponse> signedResponse) {
    ProxyWalletCreationResponse response = signedResponse.message;
    ProxyAccount proxyAccount = response.proxyAccount.message;
    ProxyAccountId proxyAccountId = proxyAccount.proxyAccountId;
    ProxyAccountEntity proxyAccountEntity = ProxyAccountEntity(
      accountId: proxyAccountId,
      accountName: "",
      bankName: "Wallet",
      balance: Amount(proxyAccount.currency, 0),
      ownerProxyId: ownerProxyId,
      signedProxyAccountJson: jsonEncode(response.proxyAccount.toJson()),
    );
    DB.instance().transaction((transaction) {
      ProxyAccountRepo.saveAccountInTransaction(transaction, proxyAccountEntity);
      EnticementRepo.dismissEnticementInTransaction(transaction, EnticementFactory.START);
    });
    return proxyAccountEntity;
  }

  Future<void> refreshAccount(ProxyAccountId accountId) async {
    print('Refreshing $accountId');
    ProxyAccountEntity proxyAccount = await proxyAccountRepo.fetchAccount(accountId);
    if (proxyAccount == null) {
      // This can happen when alert reaches earlier than API response.
      print("Account $proxyAccount not found");
      return null;
    }
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(proxyAccount.ownerProxyId);
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
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<AccountBalanceResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, AccountBalanceResponse.fromJson);
    proxyAccount.balance = signedResponse.message.balance;
    print("Account $accountId has balance => ${proxyAccount.balance}");
    proxyAccountRepo.saveAccount(proxyAccount);
  }
}
