import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/withdrawal_store.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/service_helper.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class WithdrawalService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final WithdrawalStore _withdrawalStore;

  WithdrawalService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _withdrawalStore = WithdrawalStore(appConfiguration) {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<WithdrawalEntity> withdraw(ProxyAccountEntity proxyAccount, ReceivingAccountEntity receivingAccount) async {
    String withdrawalId = uuidFactory.v4();
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
    SignedMessage<Withdrawal> signedRequest = await signMessage(request: request);

    WithdrawalEntity withdrawalEntity = _createWithdrawalEntity(
      withdrawalId,
      proxyAccount,
      receivingAccount,
      signedRequest,
    );
    WithdrawalStatusEnum status = withdrawalEntity.status;

    try {
      final signedResponse = await sendAndReceive(
        url: proxyBankingUrl,
        signedRequest: signedRequest,
        responseParser: WithdrawalResponse.fromJson,
      );
      status = signedResponse.message.status;
    } catch (e) {
      print("Error sending withdrawal to Server: $e");
    }
    return _withdrawalStore.saveWithdrawal(withdrawalEntity.copy(status: status));
  }

  Future<void> refreshWithdrawalStatus({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) async {
    WithdrawalEntity withdrawalEntity = await _withdrawalStore.fetchWithdrawal(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    );
    if (withdrawalEntity != null) {
      return _refreshWithdrawalStatus(withdrawalEntity);
    }
  }

  Future<WithdrawalEntity> _refreshWithdrawalStatus(WithdrawalEntity withdrawalEntity) async {
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: withdrawalEntity.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: WithdrawalStatusResponse.fromJson,
    );
    return await _saveWithdrawalStatus(withdrawalEntity, signedResponse.message.status);
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

  Future<WithdrawalEntity> _saveWithdrawalStatus(
    WithdrawalEntity entity,
    WithdrawalStatusEnum status,
  ) async {
    if (status == null || status == entity.status) {
      return entity;
    }
    print("Setting ${entity.withdrawalId} status to $status");
    WithdrawalEntity clone = entity.copy(
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await _withdrawalStore.saveWithdrawal(clone);
    return clone;
  }

  Future<void> processWithdrawalUpdatedAlert(WithdrawalUpdatedAlert alert) {
    return refreshWithdrawalStatus(
      proxyUniverse: alert.proxyUniverse,
      withdrawalId: alert.withdrawalId,
    );
  }

  Future<void> processWithdrawalUpdatedLiteAlert(WithdrawalUpdatedLiteAlert alert) {
    return refreshWithdrawalStatus(
      proxyUniverse: alert.proxyUniverse,
      withdrawalId: alert.withdrawalId,
    );
  }
}
