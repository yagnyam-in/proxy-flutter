import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/store/deposit_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';


class DepositService with ProxyUtils, HttpClientUtils, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyRepo proxyKeyRepo;
  final DepositStore _depositStore;

  DepositService(this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyKeyRepo,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _depositStore = DepositStore(firebaseUser: appConfiguration.firebaseUser) {
    assert(appConfiguration != null);
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
      amount: Amount(
        currency: input.currency,
        value: input.amount,
      ),
      requestingCustomer: input.requestingCustomer,
    );
    SignedMessage<DepositRequestCreationRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());

    // print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    // print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<DepositRequestCreationResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, DepositRequestCreationResponse.fromJson);
    DepositEntity depositEntity = _createDepositEntity(
      proxyAccount,
      request,
      signedResponse.message,
    );
    await _saveDeposit(depositEntity);
    return depositEntity.depositLink;
  }

  Future<void> processDepositUpdate(DepositUpdatedAlert alert) async {
    DepositEntity depositEntity =
        await _depositStore.fetchDeposit(proxyUniverse: alert.proxyUniverse, depositId: alert.depositId);
    if (depositEntity != null) {
      await _refreshDepositStatus(depositEntity);
    }
  }

  Future<void> refreshDepositStatus({
    @required String proxyUniverse,
    @required String depositId,
  }) async {
    DepositEntity depositEntity = await _depositStore.fetchDeposit(
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
    DepositEntity depositEntity = await _depositStore.fetchDeposit(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    );
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(depositEntity.destinationProxyAccountOwnerProxyId);
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
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, DepositRequestCancelResponse.fromJson);
    await _saveDeposit(depositEntity, status: signedResponse.message.status);
  }

  Future<void> _refreshDepositStatus(DepositEntity depositEntity) async {
    print('Refreshing $depositEntity');
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(depositEntity.destinationProxyAccountOwnerProxyId);
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
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, DepositRequestStatusResponse.fromJson);
    await _saveDeposit(depositEntity, status: signedResponse.message.status);
  }

  DepositEntity _createDepositEntity(
    ProxyAccountEntity proxyAccount,
    DepositRequestCreationRequest request,
    DepositRequestCreationResponse response,
  ) {
    return DepositEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      depositId: request.depositId,
      status: response.status,
      amount: request.amount,
      destinationProxyAccountId: proxyAccount.accountId,
      destinationProxyAccountOwnerProxyId: proxyAccount.ownerProxyId,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      signedDepositRequest: response.depositRequest,
      depositLink: response.depositRequest.message.depositLink,
      completed: false,
    );
  }

  Future<DepositEntity> _saveDeposit(
    DepositEntity entity, {
    DepositStatusEnum status,
  }) async {
    // print("Setting ${entity.eventId} status to $localStatus");
    DepositEntity clone = entity.copy(
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await _depositStore.saveDeposit(clone);
    return clone;
  }
}
