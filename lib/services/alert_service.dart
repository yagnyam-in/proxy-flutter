import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/banking/services/banking_service_factory.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/constants.dart';
import 'package:promo/db/device_store.dart';
import 'package:promo/db/proxy_key_store.dart';
import 'package:promo/model/device_entity.dart';
import 'package:promo/services/alert_factory.dart';
import 'package:promo/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/strings.dart';
import 'package:uuid/uuid.dart';

import 'service_factory.dart';

class AlertService with ProxyUtils, HttpClientUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final HttpClientFactory httpClientFactory;
  final MessageSigningService messageSigningService;
  final DeviceStore deviceStore;
  final ProxyKeyStore proxyKeyStore;
  final String appBackendUrl;
  final ProxyId alertProviderProxyId = Constants.PROXY_APP_BACKEND_PROXY_ID;

  String get fetchAlertsUrl => appBackendUrl;

  String get deleteAlertsUrl => appBackendUrl;

  AlertService(
    this.appConfiguration, {
    String appBackendUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageSigningService,
    @required this.deviceStore,
    @required this.proxyKeyStore,
  })  : appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.appBackendUrl));
  }

  Future<void> processLiteAlert(Map alert) async {
    LiteAlert liteAlert = AlertFactory().createLiteAlert(alert);
    if (liteAlert == null) {
      print("ignoring alert $alert it can't be parsed");
      return;
    }
    if (_isAlertProcessed(alertId: liteAlert.alertId, alertType: liteAlert.alertType)) {
      print("ignoring alert $alert as it is just processed");
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

  Future<void> _processPendingAlertsForProxy({
    @required String deviceId,
    @required ProxyId proxyId,
    DateTime fromTime,
  }) async {
    print("Process Alerts for $proxyId on $deviceId from $fromTime");
    PendingAlertsRequest request = PendingAlertsRequest(
      proxyId: proxyId,
      deviceId: deviceId,
      fromTime: fromTime,
      requestId: uuidFactory.v4(),
      alertProviderProxyId: alertProviderProxyId,
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
    SignedMessage<PendingAlertsResponse> response = ServiceFactory.messageBuilder().buildSignedMessage(
      jsonResponse,
      PendingAlertsResponse.fromJson,
    );

    List<SignableAlertMessage> alerts = response.message.alerts
        .map((signedAlert) {
          return AlertFactory().createAlert(signedAlert.type, jsonDecode(signedAlert.payload));
        })
        .where((alert) => alert != null)
        .toList();

    print("Got ${alerts.length} alerts to process");
    alerts.forEach((alert) {
      if (_isAlertProcessed(alertId: alert.alertId, alertType: alert.messageType)) {
        print("ignoring alert $alert as it is just processed");
      } else {
        _processAlert(alert);
      }
    });
    _deleteAlerts(proxyId, alerts);
    // print("Received $jsonResponse from $fetchAlertsUrl");
  }

  Future<void> _processAlert(SignableAlertMessage alert) async {
    print("processAlert $alert");
    if (alert is AccountUpdatedAlert) {
      return BankingServiceFactory.bankingService(appConfiguration).processAccountUpdatedAlert(alert);
    } else if (alert is DepositUpdatedAlert) {
      return BankingServiceFactory.depositService(appConfiguration).processDepositUpdatedAlert(alert);
    } else if (alert is WithdrawalUpdatedAlert) {
      return BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdatedAlert(alert);
    } else if (alert is PaymentAuthorizationUpdatedAlert) {
      return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
          .processPaymentAuthorizationUpdatedAlert(alert);
    } else if (alert is PaymentEncashmentUpdatedAlert) {
      return BankingServiceFactory.paymentEncashmentService(appConfiguration)
          .processPaymentEncashmentUpdatedAlert(alert);
    } else {
      print("$alert is not handled");
    }
  }

  Future<void> _processLiteAlert(LiteAlert alert) async {
    print("processLiteAlert $alert");
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
      alertProviderProxyId: alertProviderProxyId,
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

  Future<void> _deleteAlerts(ProxyId proxyId, List<SignableAlertMessage> alerts) async {
    if (alerts.isEmpty) {
      return;
    }
    DeleteAlertsRequest deleteRequest = DeleteAlertsRequest(
      proxyId: proxyId,
      deviceId: appConfiguration.deviceId,
      alertProviderProxyId: alertProviderProxyId,
      alertIds: alerts
          .map((a) => AlertId(
                alertType: a.messageType,
                alertId: a.alertId,
                proxyUniverse: a.proxyUniverse,
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

  // Its possible same alert is sent twice. Saving processing time
  static final LruMap<String, String> _recentlyProcessedAlerts = LruMap<String, String>(maximumSize: 16);

  static bool _isAlertProcessed({
    @required String alertId,
    @required String alertType,
  }) {
    if (_recentlyProcessedAlerts[alertId] == alertType) {
      return true;
    }
    _recentlyProcessedAlerts[alertId] = alertType;
    return false;
  }
}
