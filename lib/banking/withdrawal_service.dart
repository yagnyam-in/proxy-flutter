import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/withdrawal_repo.dart';
import 'package:proxy_flutter/banking/proxy_accounts_bloc.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

import 'model/withdrawal_entity.dart';

class WithdrawalService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyAccountsBloc proxyAccountsBloc;
  final ProxyKeyRepo proxyKeyRepo;
  final WithdrawalRepo withdrawalRepo;

  WithdrawalService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyAccountsBloc,
    @required this.proxyKeyRepo,
    @required this.withdrawalRepo,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<WithdrawalEntity> withdraw(ProxyAccountEntity proxyAccount,
      ReceivingAccountEntity receivingAccount) async {
    String withdrawalId = uuidFactory.v4();
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(ownerProxyId);
    Withdrawal request = new Withdrawal(
      withdrawalId: withdrawalId,
      proxyAccount: proxyAccount.signedProxyAccount,
      amount: proxyAccount.balance,
      destinationAccount: new NonProxyAccount(
        bank: receivingAccount.bank,
        accountNumber: receivingAccount.accountNumber,
        accountHolder: receivingAccount.accountHolder,
        currency: receivingAccount.currency,
        ifscCode: receivingAccount.ifscCode,
        email: receivingAccount.email,
        phone: receivingAccount.phone,
        address: receivingAccount.address,
      ),
    );
    SignedMessage<Withdrawal> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    WithdrawalEntity event = await _createWithdrawalEntity(
        withdrawalId, proxyAccount, receivingAccount, signedRequestJson);

    print("Sending $request to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalResponse> signedResponse = await messageFactory
        .buildAndVerifySignedMessage(jsonResponse, WithdrawalResponse.fromJson);
    event = await _updateStatus(event, signedResponse.message.status);
    return event;
  }

  Future<void> processWithdrawalUpdate(WithdrawalUpdatedAlert alert) async {
    String withdrawalId = alert.withdrawalId;
    print('Refreshing $alert');
    WithdrawalEntity event = await withdrawalRepo.fetchWithdrawal(
      proxyUniverse: alert.proxyUniverse,
      withdrawalId: withdrawalId,
    );
    if (event == null) {
      print("No Withdrawal found with id $withdrawalId");
      return null;
    }
    return _refreshWithdrawalStatus(event);
  }

  Future<WithdrawalEntity> refreshWithdrawalStatus({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) async {
    WithdrawalEntity withdrawalEntity = await withdrawalRepo.fetchWithdrawal(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    );
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(withdrawalEntity.payerProxyId);
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: withdrawalEntity.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, WithdrawalStatusResponse.fromJson);
    return await _updateStatus(withdrawalEntity, signedResponse.message.status);
  }

  Future<WithdrawalEntity> _refreshWithdrawalStatus(
      WithdrawalEntity event) async {
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(event.payerProxyId);
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: event.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, WithdrawalStatusResponse.fromJson);
    return await _updateStatus(event, signedResponse.message.status);
  }

  Future<WithdrawalEntity> _createWithdrawalEntity(
    String withdrawalId,
    ProxyAccountEntity proxyAccount,
    ReceivingAccountEntity receivingAccount,
    String signedRequest,
  ) {
    WithdrawalEntity withdrawalEntity = WithdrawalEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      withdrawalId: withdrawalId,
      status: WithdrawalStatusEnum.Registered,
      amount: proxyAccount.balance,
      payerAccountId: proxyAccount.accountId,
      payerProxyId: proxyAccount.ownerProxyId,
      signedWithdrawalRequestJson: signedRequest,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      destinationAccountBank: receivingAccount.accountNumber,
      destinationAccountNumber: receivingAccount.bank,
      receivingAccountId: receivingAccount.id,
      completed: false,
    );
    return withdrawalRepo.saveWithdrawal(withdrawalEntity);
  }

  Future<WithdrawalEntity> _updateStatus(
    WithdrawalEntity entity,
    WithdrawalStatusEnum status,
  ) async {
    print("Setting ${entity.withdrawalId} status to $status");
    WithdrawalEntity clone = entity.copy(
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await withdrawalRepo.saveWithdrawal(clone);
    return clone;
  }
}
