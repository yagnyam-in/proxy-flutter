import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/deposit_store.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/service_helper.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class DepositService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final DepositStore _depositStore;

  DepositService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _depositStore = DepositStore(appConfiguration) {
    assert(appConfiguration != null);
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<String> depositLink(
    ProxyAccountEntity proxyAccount,
    DepositRequestInput input,
  ) async {
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
    final signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: DepositRequestCreationResponse.fromJson,
    );
    DepositEntity depositEntity = _createDepositEntity(
      proxyAccount,
      request,
      signedResponse.message,
    );
    await _depositStore.saveDeposit(depositEntity);
    return depositEntity.depositLink;
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
    DepositRequestCancelRequest request = DepositRequestCancelRequest(
      requestId: uuidFactory.v4(),
      depositRequest: depositEntity.signedDepositRequest,
    );
    final signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: DepositRequestCancelResponse.fromJson,
    );
    await _saveDepositStatus(depositEntity, signedResponse.message.status);
  }

  Future<void> _refreshDepositStatus(DepositEntity depositEntity) async {
    print('Refreshing $depositEntity');
    DepositRequestStatusRequest request = DepositRequestStatusRequest(
      requestId: uuidFactory.v4(),
      depositRequest: depositEntity.signedDepositRequest,
    );
    final signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      signedRequest: signedRequest,
      responseParser: DepositRequestStatusResponse.fromJson,
      url: proxyBankingUrl,
    );
    await _saveDepositStatus(depositEntity, signedResponse.message.status);
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

  Future<DepositEntity> _saveDepositStatus(
    DepositEntity entity,
    DepositStatusEnum status,
  ) async {
    if (status == null || status == entity.status) {
      return entity;
    }
    // print("Setting ${entity.eventId} status to $localStatus");
    DepositEntity clone = entity.copy(
      status: status,
      lastUpdatedTime: DateTime.now(),
    );
    await _depositStore.saveDeposit(clone);
    return clone;
  }

  Future<void> processDepositUpdatedAlert(DepositUpdatedAlert alert) {
    return refreshDepositStatus(
      proxyUniverse: alert.proxyUniverse,
      depositId: alert.depositId,
    );
  }

  Future<void> processDepositUpdatedLiteAlert(DepositUpdatedLiteAlert alert) {
    return refreshDepositStatus(
      proxyUniverse: alert.proxyUniverse,
      depositId: alert.depositId,
    );
  }
}
