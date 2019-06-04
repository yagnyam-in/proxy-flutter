import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/deposit_repo.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

import 'model/deposit_entity.dart';

class DepositService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyRepo proxyKeyRepo;
  final DepositRepo depositRepo;

  DepositService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyKeyRepo,
    @required this.depositRepo,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<String> depositLink(
    ProxyAccountEntity proxyAccount,
    DepositRequestInput input,
  ) async {
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(ownerProxyId);
    String depositId = uuidFactory.v4();
    DepositRequestCreationRequest request = DepositRequestCreationRequest(
      depositId: depositId,
      proxyAccount: proxyAccount.signedProxyAccount,
      message: input.message,
      amount: Amount(input.currency, input.amount),
      requestingCustomer: input.requestingCustomer,
    );
    SignedMessage<DepositRequestCreationRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    DepositEntity depositEntity = await _createDepositEntity(proxyAccount, request);

    // print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    // print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositRequestCreationResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, DepositRequestCreationResponse.fromJson);
    depositEntity = await _updateDeposit(depositEntity,
        signedDepositRequest: signedResponse.message.depositRequest,
        status: signedResponse.message.status);
    return signedResponse.message.depositLink;
  }

  Future<void> processDepositUpdate(DepositUpdatedAlert alert) async {
    DepositEntity depositEntity = await depositRepo.fetchDeposit(
        proxyUniverse: alert.proxyUniverse, depositId: alert.depositId);
    if (depositEntity != null) {
      await _refreshDepositStatus(depositEntity);
    }
  }

  Future<void> refreshDepositStatus({
    @required String proxyUniverse,
    @required String depositId,
  }) async {
    DepositEntity depositEntity = await depositRepo.fetchDeposit(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    );
    if (depositEntity != null) {
      await _refreshDepositStatus(depositEntity);
    }
  }

  Future<void> cancelDeposit({
    @required String proxyUniverse,
    @required String depositId,
  }) async {
    print('Cancelling $proxyUniverse/$depositId');
    DepositEntity depositEntity = await depositRepo.fetchDeposit(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    );
    ProxyKey proxyKey = await proxyKeyRepo
        .fetchProxyKey(depositEntity.destinationProxyAccountOwnerProxyId);
    DepositRequestCancelRequest request = DepositRequestCancelRequest(
      requestId: uuidFactory.v4(),
      depositRequest: depositEntity.signedDepositRequest,
    );
    SignedMessage<DepositRequestCancelRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());

    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositRequestCancelResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, DepositRequestCancelResponse.fromJson);
    await _updateDeposit(depositEntity, status: signedResponse.message.status);
  }

  Future<void> _refreshDepositStatus(DepositEntity depositEntity) async {
    print('Refreshing $depositEntity');
    ProxyKey proxyKey = await proxyKeyRepo
        .fetchProxyKey(depositEntity.destinationProxyAccountOwnerProxyId);
    DepositRequestStatusRequest request = DepositRequestStatusRequest(
      requestId: uuidFactory.v4(),
      depositRequest: depositEntity.signedDepositRequest,
    );
    SignedMessage<DepositRequestStatusRequest> signedRequest =
    await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());

    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositRequestStatusResponse> signedResponse =
    await messageFactory.buildAndVerifySignedMessage(
        jsonResponse, DepositRequestStatusResponse.fromJson);
    await _updateDeposit(depositEntity, status: signedResponse.message.status);
  }


  Future<DepositEntity> _createDepositEntity(
    ProxyAccountEntity proxyAccount,
    DepositRequestCreationRequest request,
  ) {
    DepositEntity depositEntity = DepositEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      depositId: request.depositId,
      status: DepositStatusEnum.InProcess,
      amount: request.amount,
      destinationProxyAccountId: proxyAccount.accountId,
      destinationProxyAccountOwnerProxyId: proxyAccount.ownerProxyId,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      completed: false,
    );
    return depositRepo.saveDeposit(depositEntity);
  }

  Future<DepositEntity> _updateDeposit(
    DepositEntity entity, {
    SignedMessage<DepositRequest> signedDepositRequest,
    DepositStatusEnum status,
  }) async {
    // print("Setting ${entity.eventId} status to $localStatus");
    DepositEntity clone = entity.copy(
      signedDepositRequestJson: signedDepositRequest != null
          ? jsonEncode(signedDepositRequest.toJson())
          : null,
      depositLink: signedDepositRequest?.message?.depositLink,
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await depositRepo.saveDeposit(clone);
    return clone;
  }
}
