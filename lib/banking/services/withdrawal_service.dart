import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/withdrawal_store.dart';
import 'package:promo/banking/model/proxy_account_entity.dart';
import 'package:promo/banking/model/receiving_account_entity.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/services/service_helper.dart';
import 'package:promo/url_config.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
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
        httpClientFactory = httpClientFactory ?? HttpClientUtils.httpClient(),
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
    SignedMessage<Withdrawal> signedRequest = await signMessage(
      signer: proxyAccount.ownerProxyId,
      request: request,
    );

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

  Future<void> _refreshWithdrawal(WithdrawalEntity withdrawalEntity) async {
    if (withdrawalEntity == null) {
      return withdrawalEntity;
    }
    final withdrawal = withdrawalEntity.signedWithdrawal;
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: withdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest = await signMessage(
      signer: withdrawalEntity.payerProxyId,
      request: request,
    );
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
      payerProxyAccountId: proxyAccount.proxyAccountId,
      payerProxyId: proxyAccount.ownerProxyId,
      signedWithdrawal: signedRequest,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      destinationAccountBank: receivingAccount.accountNumber,
      destinationAccountNumber: receivingAccount.bankName,
      receivingAccountId: receivingAccount.internalId,
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
    return _refreshWithdrawalById(
      bankId: alert.proxyAccountId.bankId,
      withdrawalId: alert.withdrawalId,
    );
  }

  Future<void> processWithdrawalUpdatedLiteAlert(WithdrawalUpdatedLiteAlert alert) {
    return _refreshWithdrawalById(
      bankId: alert.proxyAccountId.bankId,
      withdrawalId: alert.withdrawalId,
    );
  }

  Future<void> _refreshWithdrawalById({
    @required String bankId,
    @required String withdrawalId,
  }) async {
    WithdrawalEntity withdrawal = await _withdrawalStore.fetch(
      bankId: bankId,
      withdrawalId: withdrawalId,
    );
    if (withdrawal != null) {
      return _refreshWithdrawal(withdrawal);
    }
  }

  Future<void> refreshWithdrawalByInternalId(String internalId) async {
    WithdrawalEntity withdrawal = await _withdrawalStore.fetchByInternalId(internalId);
    if (withdrawal != null) {
      return _refreshWithdrawal(withdrawal);
    }
  }
}
