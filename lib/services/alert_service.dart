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
  String get alertsUrl => appBackendUrl + "/alerts";

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
    print("Sending $signedRequestJson to $alertsUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      alertsUrl,
      body: signedRequestJson,
    );
    List<Map> alerts = jsonDecode(jsonResponse);
    alerts.forEach((alertJson) async {
      final alert = await AlertFactory(appConfiguration).createAlert(alertJson);
      await _processAlert(alert);
    });
    print("Received $jsonResponse from $alertsUrl");
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
      return BankingServiceFactory.paymentAuthorizationService(appConfiguration).processPaymentAuthorizationUpdate(alert);
    } else if (alert is PaymentEncashmentUpdatedAlert) {
      return BankingServiceFactory.paymentEncashmentService(appConfiguration).processPaymentEncashmentUpdate(alert);
    } else {
      print("$alert is not handled");
    }
  }
}
