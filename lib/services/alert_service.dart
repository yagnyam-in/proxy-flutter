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
    await _processLiteAlert(alert);
    await _deleteAlert(alert);
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

  Future<void> _processAlert(SignedMessage<SignableAlertMessage> alert) async {
    if (alert.message is AccountUpdatedAlert) {
      return BankingServiceFactory.bankingService(appConfiguration).processAccountUpdate(alert);
    } else if (alert is DepositUpdatedAlert) {
      return BankingServiceFactory.depositService(appConfiguration).processDepositUpdate(alert);
    } else if (alert is WithdrawalUpdatedAlert) {
      return BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdate(alert);
    } else if (alert is PaymentAuthorizationUpdatedAlert) {
      return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
          .processPaymentAuthorizationUpdate(alert);
    } else if (alert is PaymentEncashmentUpdatedAlert) {
      return BankingServiceFactory.paymentEncashmentService(appConfiguration).processPaymentEncashmentUpdate(alert);
    } else {
      print("$alert is not handled");
    }
  }

  Future<void> _processLiteAlert(Map alert) async {
    switch (alert[SignableAlertMessage.FIELD_ALERT_TYPE]) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return BankingServiceFactory.bankingService(appConfiguration).processLiteAccountUpdate(alert);
      case DepositUpdatedAlert.ALERT_TYPE:
        return BankingServiceFactory.depositService(appConfiguration).processLiteDepositUpdate(alert);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return BankingServiceFactory.withdrawalService(appConfiguration).processLiteWithdrawalUpdate(alert);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
            .processLitePaymentAuthorizationUpdate(alert);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return BankingServiceFactory.paymentEncashmentService(appConfiguration)
            .processLitePaymentEncashmentUpdate(alert);
      default:
        print("Unknnown Alert $alert");
        return null;
    }
  }

  Future<void> _deleteAlert(Map alert) async {
    ProxyId proxyId = ProxyId.fromUniqueId(alert[SignableAlertMessage.FIELD_RECEIVER_PROXY_ID]);
    DeleteAlertsRequest deleteRequest = DeleteAlertsRequest(
      proxyId: proxyId,
      deviceId: appConfiguration.deviceId,
      alertIds: [
        AlertId(
          alertId: alert[SignableAlertMessage.FIELD_ALERT_ID],
          alertType: alert[SignableAlertMessage.FIELD_ALERT_TYPE],
          proxyUniverse: alert[SignableAlertMessage.FIELD_PROXY_UNIVERSE],
        ),
      ],
      requestId: uuidFactory.v4(),
    );
    _processDeleteAlertRequest(proxyId, deleteRequest);
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
