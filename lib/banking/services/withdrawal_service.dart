import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/withdrawal_store.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class WithdrawalService with ProxyUtils, HttpClientUtils, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final WithdrawalStore _withdrawalStore;
  final ProxyKeyStore _proxyKeyStore;

  WithdrawalService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _proxyKeyStore = ProxyKeyStore(appConfiguration.account),
        _withdrawalStore = WithdrawalStore(appConfiguration) {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<WithdrawalEntity> withdraw(ProxyAccountEntity proxyAccount, ReceivingAccountEntity receivingAccount) async {
    String withdrawalId = uuidFactory.v4();
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(ownerProxyId);
    Withdrawal request = new Withdrawal(
      withdrawalId: withdrawalId,
      proxyAccount: proxyAccount.signedProxyAccount,
      amount: proxyAccount.balance,
      destinationAccount: new NonProxyAccount(
        bank: receivingAccount.bankName,
        accountNumber: receivingAccount.accountNumber,
        accountHolder: receivingAccount.accountHolder,
        currency: receivingAccount.currency,
        ifscCode: receivingAccount.ifscCode,
        email: receivingAccount.email,
        phone: receivingAccount.phone,
        address: receivingAccount.address,
      ),
    );
    SignedMessage<Withdrawal> signedRequest = await messageSigningService.signMessage(request, proxyKey);

    WithdrawalEntity withdrawalEntity = _createWithdrawalEntity(
      withdrawalId,
      proxyAccount,
      receivingAccount,
      signedRequest,
    );
    WithdrawalStatusEnum status = withdrawalEntity.status;

    try {
      String signedRequestJson = jsonEncode(signedRequest.toJson());
      print("Sending $request to $proxyBankingUrl");
      String jsonResponse = await post(
        httpClientFactory(),
        proxyBankingUrl,
        body: signedRequestJson,
      );
      print("Received $jsonResponse from $proxyBankingUrl");
      SignedMessage<WithdrawalResponse> signedResponse =
          await messageFactory.buildAndVerifySignedMessage(jsonResponse, WithdrawalResponse.fromJson);
      status = signedResponse.message.status;
    } catch (e) {
      print("Error sending withdrawal to Server: $e");
    }
    return _saveWithdrawal(withdrawalEntity, status);
  }

  Future<void> processWithdrawalUpdate(WithdrawalUpdatedAlert alert) async {
    String withdrawalId = alert.withdrawalId;
    print('Refreshing $alert');
    WithdrawalEntity withdrawalEntity = await _withdrawalStore.fetchWithdrawal(
      proxyUniverse: alert.proxyUniverse,
      withdrawalId: withdrawalId,
    );
    if (withdrawalEntity == null) {
      print("No Withdrawal found with id $withdrawalId");
      return null;
    }
    return _refreshWithdrawalStatus(withdrawalEntity);
  }

  Future<WithdrawalEntity> refreshWithdrawalStatus({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) async {
    WithdrawalEntity withdrawalEntity = await _withdrawalStore.fetchWithdrawal(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    );
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(withdrawalEntity.payerProxyId);
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: withdrawalEntity.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      body: signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, WithdrawalStatusResponse.fromJson);
    return await _saveWithdrawal(withdrawalEntity, signedResponse.message.status);
  }

  Future<WithdrawalEntity> _refreshWithdrawalStatus(WithdrawalEntity withdrawalEntity) async {
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(withdrawalEntity.payerProxyId);
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: withdrawalEntity.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      body: signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, WithdrawalStatusResponse.fromJson);
    return await _saveWithdrawal(withdrawalEntity, signedResponse.message.status);
  }

  WithdrawalEntity _createWithdrawalEntity(
    String withdrawalId,
    ProxyAccountEntity proxyAccount,
    ReceivingAccountEntity receivingAccount,
    SignedMessage<Withdrawal> signedRequest,
  ) {
    return WithdrawalEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      withdrawalId: withdrawalId,
      status: WithdrawalStatusEnum.Created,
      amount: proxyAccount.balance,
      payerAccountId: proxyAccount.accountId,
      payerProxyId: proxyAccount.ownerProxyId,
      signedWithdrawal: signedRequest,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      destinationAccountBank: receivingAccount.accountNumber,
      destinationAccountNumber: receivingAccount.bankName,
      receivingAccountId: receivingAccount.accountId,
      completed: false,
    );
  }

  Future<WithdrawalEntity> _saveWithdrawal(
    WithdrawalEntity entity,
    WithdrawalStatusEnum status,
  ) async {
    print("Setting ${entity.withdrawalId} status to $status");
    WithdrawalEntity clone = entity.copy(
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await _withdrawalStore.saveWithdrawal(clone);
    return clone;
  }
}
