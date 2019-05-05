import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/db/event_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

import 'model/deposit_event_entity.dart';

class DepositService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyRepo proxyKeyRepo;
  final EventBloc eventBloc;
  final EventRepo eventRepo;

  DepositService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyKeyRepo,
    @required this.eventBloc,
    @required this.eventRepo,
  })  : proxyBankingUrl =
            proxyBankingUrl ?? "https://proxy-banking.appspot.com/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<String> depositLink(
      ProxyAccountEntity proxyAccount, DepositRequestInput input) async {
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(ownerProxyId);
    String depositId = uuidFactory.v4();
    DepositRequest request = DepositRequest(
      depositId: depositId,
      proxyAccount: proxyAccount.signedProxyAccount,
      message: input.message,
      amount: Amount(input.currency, input.amount),
      requestingCustomer: input.requestingCustomer,
    );
    SignedMessage<DepositRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    DepositEventEntity event =
        await _createEvent(proxyAccount, request, signedRequestJson);

    // print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    // print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositResponse> signedResponse = await messageFactory
        .buildAndVerifySignedMessage(jsonResponse, DepositResponse.fromJson);
    event = await _updateStatus(event, signedResponse.message.status);
    return signedResponse.message.depositLink;
  }

  Future<void> processDepositUpdate(DepositUpdatedAlert alert) async {
    DepositEventEntity event =
    await eventRepo.fetchEvent(EventType.Deposit, alert.depositId);
    if (event == null) {
      print("No Deposit Event found with id ${alert.proxyUniverse}:${alert.depositId}");
      return null;
    }
    return refreshDepositStatus(event);
  }

  Future<void> refreshDepositStatus(DepositEventEntity event) async {
    print('Refreshing $event');

    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(event.ownerId);
    DepositStatusRequest request = DepositStatusRequest(
      requestId: uuidFactory.v4(),
      request: event.signedDepositRequest,
    );
    SignedMessage<DepositStatusRequest> signedRequest =
    await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());

    // print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    // print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositStatusResponse> signedResponse =
    await messageFactory.buildAndVerifySignedMessage(
        jsonResponse, DepositStatusResponse.fromJson);
    await _updateStatus(event, signedResponse.message.status);
  }


  Future<DepositEventEntity> _createEvent(ProxyAccountEntity proxyAccount, DepositRequest request, String signedRequest) async {
    DepositEventEntity event = DepositEventEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      eventId: request.depositId,
      status: DepositEventStatus.InProcess,
      amount: request.amount,
      accountId: proxyAccount.accountId,
      ownerId: proxyAccount.ownerProxyId,
      signedDepositRequestJson: signedRequest,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
    );
    await eventBloc.saveEvent(event);
    return event;
  }

  Future<DepositEventEntity> _updateStatus(
      DepositEventEntity entity, DepositStatusEnum status) async {
    DepositEventStatus localStatus = DepositEventEntity.toLocalStatus(status);
    // print("Setting ${entity.eventId} status to $localStatus");
    DepositEventEntity clone = entity.copy(
      status: localStatus,
      lastUpdatedTime: DateTime.now(),
    );
    await eventBloc.saveEvent(clone);
    return clone;
  }
}
