import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/proxy_accounts_bloc.dart';
import 'package:proxy_flutter/db/event_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

import 'model/withdrawal_event_entity.dart';

class WithdrawalService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyAccountsBloc proxyAccountsBloc;
  final ProxyKeyRepo proxyKeyRepo;
  final EventBloc eventBloc;
  final EventRepo eventRepo;

  WithdrawalService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyAccountsBloc,
    @required this.proxyKeyRepo,
    @required this.eventBloc,
    @required this.eventRepo,
  })  : proxyBankingUrl = proxyBankingUrl ?? "https://proxy-banking.appspot.com/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<WithdrawalEventEntity> withdraw(
      ProxyAccountEntity proxyAccount, ReceivingAccountEntity receivingAccount) async {
    String withdrawalId = uuidFactory.v4();
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(ownerProxyId);
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
    SignedMessage<Withdrawal> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    WithdrawalEventEntity event = await _createEvent(withdrawalId, proxyAccount, receivingAccount, signedRequestJson);

    print("Sending $request to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, WithdrawalResponse.fromJson);
    event = await _updateStatus(event, signedResponse.message.status);
    return event;
  }

  Future<void> processWithdrawalUpdate(WithdrawalUpdatedAlert alert) async {
    String withdrawalId = alert.withdrawalId;
    print('Refreshing $alert');
    WithdrawalEventEntity event = await eventRepo.fetchEvent(alert.proxyUniverse, EventType.Withdraw, withdrawalId);
    if (event == null) {
      print("No Withdrawal Event found with id $withdrawalId");
      return null;
    }
    return refreshWithdrawalStatus(event);
  }

  Future<WithdrawalEventEntity> refreshWithdrawalStatus(WithdrawalEventEntity event) async {
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(event.ownerId);
    WithdrawalStatusRequest request = WithdrawalStatusRequest(
      requestId: uuidFactory.v4(),
      request: event.signedWithdrawal,
    );
    SignedMessage<WithdrawalStatusRequest> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<WithdrawalStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, WithdrawalStatusResponse.fromJson);
    return await _updateStatus(event, signedResponse.message.status);
  }

  Future<WithdrawalEventEntity> _createEvent(String withdrawalId, ProxyAccountEntity proxyAccount,
      ReceivingAccountEntity receivingAccount, String signedRequest) async {
    WithdrawalEventEntity event = WithdrawalEventEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      eventId: withdrawalId,
      status: WithdrawalEventStatus.InProcess,
      amount: proxyAccount.balance,
      accountId: proxyAccount.accountId,
      ownerId: proxyAccount.ownerProxyId,
      signedWithdrawalRequestJson: signedRequest,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      destinationAccountBank: receivingAccount.accountNumber,
      destinationAccountNumber: receivingAccount.bank,
    );
    await eventBloc.saveEvent(event);
    return event;
  }

  Future<WithdrawalEventEntity> _updateStatus(WithdrawalEventEntity entity, WithdrawalStatusEnum status) async {
    WithdrawalEventStatus localStatus = WithdrawalEventEntity.toLocalStatus(status);
    print("Setting ${entity.eventId} status to $localStatus");
    WithdrawalEventEntity clone = entity.copy(
      status: localStatus,
      lastUpdatedTime: DateTime.now(),
    );
    await eventBloc.saveEvent(clone);
    return clone;
  }
}
