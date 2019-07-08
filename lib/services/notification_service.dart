import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class NotificationService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String appBackendUrl;
  final HttpClientFactory httpClientFactory;
  final MessageSigningService messageSigningService;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _started = false;

  NotificationService({
    String appBackendUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageSigningService,
  })  : appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.appBackendUrl));
  }

  void start() {
    if (!_started) {
      _start();
      _started = true;
    }
  }

  void refreshToken() {
    _firebaseMessaging.getToken().then(tokenRefresh, onError: tokenRefreshFailure);
  }

  void _start() {
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.onTokenRefresh.listen(tokenRefresh, onError: tokenRefreshFailure);
    _firebaseMessaging.configure(
      onMessage: onMessage,
      onLaunch: onLaunch,
      onResume: onResume,
    );
  }

  void tokenRefresh(String newToken) async {
    // print("New FCM Token $newToken");
    AppConfiguration appConfiguration = AppConfigurationBloc.instance.appConfiguration;
    if (newToken != null && appConfiguration != null && appConfiguration.isComplete) {
      ProxyKeyStore proxyKeyStore = ProxyKeyStore(appConfiguration);
      List<ProxyKey> outdatedProxies = await proxyKeyStore.fetchProxiesWithoutFcmToken(newToken);
      print("Got ${outdatedProxies.length} proxies to update");
      outdatedProxies.forEach((key) => _updateToken(proxyKeyStore, key, newToken));
    } else {
      print("Can't update FCM Token as AppConfiguration is incomplete");
    }
  }

  void _updateToken(ProxyKeyStore proxyKeyStore, ProxyKey proxyKey, String newToken) async {
    print("Updating FCM Token for ${proxyKey.id}");
    ProxyCustomerUpdateRequest request = new ProxyCustomerUpdateRequest(
      requestId: uuidFactory.v4(),
      proxyId: proxyKey.id,
      gcmToken: newToken,
    );
    SignedMessage<ProxyCustomerUpdateRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $appBackendUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      appBackendUrl,
      body: signedRequestJson,
    );
    print("Received $jsonResponse from $appBackendUrl");
    proxyKeyStore.updateFcmToken(proxyKey, newToken);
  }

  void tokenRefreshFailure(error) {
    print("FCM token refresh failed with error $error");
  }

  Future<void> onMessage(Map<String, dynamic> message) async {
    print("onMessage $message");
    Map<dynamic, dynamic> data = message['data'];
    print('data: $data');
    String type = data != null ? data['alertType'] : null;
    print('type: $type');
    AppConfiguration appConfiguration = AppConfigurationBloc.instance.appConfiguration;
    if (appConfiguration == null || !appConfiguration.isComplete) {
      print("Ignoring $message as App Config is null or not complete");
      return null;
    }
    if (type == AccountUpdatedAlert.ALERT_TYPE) {
      AccountUpdatedAlert alert = AccountUpdatedAlert.fromJson(data);
      BankingServiceFactory.bankingService(appConfiguration).refreshAccount(alert.proxyAccountId);
    } else if (type == WithdrawalUpdatedAlert.ALERT_TYPE) {
      WithdrawalUpdatedAlert alert = WithdrawalUpdatedAlert.fromJson(data);
      BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdate(alert);
    } else if (type == DepositUpdatedAlert.ALERT_TYPE) {
      DepositUpdatedAlert alert = DepositUpdatedAlert.fromJson(data);
      BankingServiceFactory.depositService(appConfiguration).processDepositUpdate(alert);
    } else if (type == PaymentAuthorizationUpdatedAlert.ALERT_TYPE) {
      PaymentAuthorizationUpdatedAlert alert = PaymentAuthorizationUpdatedAlert.fromJson(data);
      BankingServiceFactory.paymentAuthorizationService(appConfiguration).processPaymentAuthorizationUpdate(alert);
    } else if (type == PaymentEncashmentUpdatedAlert.ALERT_TYPE) {
      PaymentEncashmentUpdatedAlert alert = PaymentEncashmentUpdatedAlert.fromJson(data);
      BankingServiceFactory.paymentEncashmentService(appConfiguration).processPaymentEncashmentUpdate(alert);
    }
    return null;
  }

  Future<void> onLaunch(Map<String, dynamic> message) {
    print("onLaunch $message");
    return null;
  }

  Future<void> onResume(Map<String, dynamic> message) {
    print("onResume $message");
    return null;
  }
}
