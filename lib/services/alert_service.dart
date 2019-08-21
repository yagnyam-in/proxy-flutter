import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/device_store.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/model/device_entity.dart';
import 'package:proxy_flutter/services/alert_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:quiver/strings.dart';
import 'package:uuid/uuid.dart';

class AlertService with ProxyUtils, HttpClientUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final HttpClientFactory httpClientFactory;
  final MessageSigningService messageSigningService;
  final DeviceStore deviceStore;
  final ProxyKeyStore proxyKeyStore;
  final String appBackendUrl;

  String get fetchAlertsUrl => appBackendUrl + "/alerts/get";

  String get deleteAlertsUrl => appBackendUrl + "/alerts";

  AlertService(
    this.appConfiguration, {
    String appBackendUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageSigningService,
    @required this.deviceStore,
    @required this.proxyKeyStore,
  })  : appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/app",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.appBackendUrl));
  }

  Future<void> _processPendingAlertsForProxy({
    @required String deviceId,
    @required ProxyId proxyId,
    DateTime fromTime,
  }) async {
    PendingAlertsRequest request = PendingAlertsRequest(
      proxyId: proxyId,
      deviceId: deviceId,
      fromTime: fromTime,
      requestId: uuidFactory.v4(),
    );
    ProxyKey proxyKey = await proxyKeyStore.fetchProxyKey(proxyId);
    if (proxyKey == null) {
      return;
    }
    SignedMessage<PendingAlertsRequest> signedRequest = await messageSigningService.sign(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    // print("Sending $signedRequestJson to $fetchAlertsUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      fetchAlertsUrl,
      body: signedRequestJson,
    );
    List alertsJson = jsonDecode(jsonResponse);
    List<SignedMessage<SignableAlertMessage>> alerts = await Future.wait(
        alertsJson.map((alertJson) => AlertFactory(appConfiguration).createAlert(alertJson)).toList());
    alerts.forEach(_processAlert);
    _deleteAlerts(proxyId, alerts);
    // print("Received $jsonResponse from $fetchAlertsUrl");
  }

  Future<void> processLiteAlert(Map alert) async {
    print("processAlert $alert");
    LiteAlert liteAlert = AlertFactory(appConfiguration).createLiteAlert(alert);
    if (liteAlert == null) {
      print("ignoring alert $alert");
      return;
    }
    await _processLiteAlert(liteAlert);
    await _deleteAlert(liteAlert);
  }

  Future<void> processPendingAlerts() async {
    print("processPendingAlerts");
    DeviceEntity device = await deviceStore.fetchDevice(appConfiguration.deviceId);
    if (device == null) {
      return;
    }
    DateTime processedTill = DateTime.now();
    await Future.wait(
      device.proxyIdList.map(
        (proxyId) => _processPendingAlertsForProxy(
          deviceId: device.deviceId,
          proxyId: proxyId,
          fromTime: device.alertsProcessedTill,
        ),
      ),
    );
    await deviceStore.saveDevice(device.copy(alertsProcessedTill: processedTill));
  }

  Future<void> _processAlert(SignedMessage<SignableAlertMessage> signedAlert) async {
    SignableAlertMessage alert = signedAlert.message;
    if (alert is AccountUpdatedAlert) {
      return BankingServiceFactory.bankingService(appConfiguration).processAccountUpdatedAlert(signedAlert);
    } else if (alert is DepositUpdatedAlert) {
      return BankingServiceFactory.depositService(appConfiguration).processDepositUpdatedAlert(signedAlert);
    } else if (alert is WithdrawalUpdatedAlert) {
      return BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdatedAlert(signedAlert);
    } else if (alert is PaymentAuthorizationUpdatedAlert) {
      return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
          .processPaymentAuthorizationUpdatedAlert(signedAlert);
    } else if (alert is PaymentEncashmentUpdatedAlert) {
      return BankingServiceFactory.paymentEncashmentService(appConfiguration)
          .processPaymentEncashmentUpdatedAlert(signedAlert);
    } else {
      print("$alert is not handled");
    }
  }

  Future<void> _processLiteAlert(LiteAlert alert) async {
    if (alert is AccountUpdatedLiteAlert) {
      return BankingServiceFactory.bankingService(appConfiguration).processAccountUpdatedLiteAlert(alert);
    } else if (alert is DepositUpdatedLiteAlert) {
      return BankingServiceFactory.depositService(appConfiguration).processDepositUpdatedLiteAlert(alert);
    } else if (alert is WithdrawalUpdatedLiteAlert) {
      return BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdatedLiteAlert(alert);
    } else if (alert is PaymentAuthorizationUpdatedLiteAlert) {
      return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
          .processPaymentAuthorizationUpdatedLiteAlert(alert);
    } else if (alert is PaymentEncashmentUpdatedLiteAlert) {
      return BankingServiceFactory.paymentEncashmentService(appConfiguration)
          .processPaymentEncashmentUpdatedLiteAlert(alert);
    } else {
      print("$alert is not handled");
    }
  }

  Future<void> _deleteAlert(LiteAlert alert) async {
    DeleteAlertsRequest deleteRequest = DeleteAlertsRequest(
      proxyId: alert.receiverProxyId,
      deviceId: appConfiguration.deviceId,
      alertIds: [
        AlertId(
          alertId: alert.alertId,
          alertType: alert.alertType,
          proxyUniverse: alert.proxyUniverse,
        ),
      ],
      requestId: uuidFactory.v4(),
    );
    _processDeleteAlertRequest(alert.receiverProxyId, deleteRequest);
  }

  Future<void> _deleteAlerts(ProxyId proxyId, List<SignedMessage<SignableAlertMessage>> alerts) async {
    if (alerts.isEmpty) {
      return;
    }
    DeleteAlertsRequest deleteRequest = DeleteAlertsRequest(
      proxyId: proxyId,
      deviceId: appConfiguration.deviceId,
      alertIds: alerts
          .map((a) => AlertId(
                alertType: a.type,
                alertId: a.message.alertId,
                proxyUniverse: a.message.proxyUniverse,
              ))
          .toList(),
      requestId: uuidFactory.v4(),
    );
    _processDeleteAlertRequest(proxyId, deleteRequest);
  }

  Future<void> _processDeleteAlertRequest(ProxyId proxyId, DeleteAlertsRequest deleteRequest) async {
    ProxyKey proxyKey = await proxyKeyStore.fetchProxyKey(proxyId);
    if (proxyKey == null) {
      return;
    }
    SignedMessage<DeleteAlertsRequest> signedRequest = await messageSigningService.sign(deleteRequest, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    // print("Sending $signedRequestJson to $deleteAlertsUrl");
    await post(
      httpClientFactory(),
      deleteAlertsUrl,
      body: signedRequestJson,
    );
  }
}
