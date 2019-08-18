import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/device_store.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:uuid/uuid.dart';

class NotificationService with ProxyUtils, HttpClientUtils {
  final Uuid uuidFactory = Uuid();
  final HttpClientFactory httpClientFactory;
  final MessageSigningService messageSigningService;
  final String appBackendUrl;
  String get subscribeForAlertsUrl => appBackendUrl + "/alerts";

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _started = false;

  NotificationService({
    String appBackendUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageSigningService,
  })  : appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/app",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.appBackendUrl));
  }

  void start() {
    if (!_started) {
      _start();
      _started = true;
      _refreshToken();
    }
  }

  void _refreshToken() {
    _firebaseMessaging.getToken().then(_tokenRefresh, onError: _tokenRefreshFailure);
  }

  void _start() {
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.onTokenRefresh.listen(_tokenRefresh, onError: _tokenRefreshFailure);
    _firebaseMessaging.configure(
      onMessage: _onMessage,
      onLaunch: _onLaunch,
      onResume: _onResume,
    );
  }

  void _tokenRefresh(String newToken) async {
    // print("New FCM Token $newToken");
    AppConfiguration appConfiguration = AppConfigurationBloc.instance.appConfiguration;
    if (newToken != null && appConfiguration != null && appConfiguration.isComplete) {
      ProxyKeyStore proxyKeyStore = ProxyKeyStore(appConfiguration);
      DeviceStore deviceStore = DeviceStore(appConfiguration);
      Set<ProxyId> uptoDateProxies = await deviceStore.fetchProxiesWithFcmToken(
        deviceId: appConfiguration.deviceId,
        fcmToken: newToken,
      );
      List<ProxyKey> allProxies = await proxyKeyStore.fetchProxyKeys(exclusion: uptoDateProxies);
      allProxies.forEach(
        (key) => _updateToken(
          key,
          deviceId: appConfiguration.deviceId,
          fcmToken: newToken,
        ),
      );
      deviceStore.updateFcmToken(
        deviceId: appConfiguration.deviceId,
        fcmToken: newToken,
        proxyKeys: allProxies,
      );
    } else {
      print("Can't update FCM Token as AppConfiguration is incomplete");
    }
  }

  void _updateToken(
    ProxyKey proxyKey, {
    @required String deviceId,
    @required String fcmToken,
  }) async {
    print("Updating FCM Token for ${proxyKey.id} on Device $deviceId");
    SubscribeForAlertsRequest request = new SubscribeForAlertsRequest(
      requestId: uuidFactory.v4(),
      proxyId: proxyKey.id,
      deviceId: deviceId,
      fcmToken: fcmToken,
    );
    SignedMessage<SubscribeForAlertsRequest> signedRequest = await messageSigningService.sign(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    // print("Sending $signedRequestJson to $subscribeForAlertsUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      subscribeForAlertsUrl,
      body: signedRequestJson,
    );
    // print("Received $jsonResponse from $subscribeForAlertsUrl");
  }

  void _tokenRefreshFailure(error) {
    print("FCM token refresh failed with error $error");
  }

  Future<void> _onMessage(Map<String, dynamic> message) async {
    print("onMessage $message");
    AppConfiguration appConfiguration = AppConfigurationBloc.instance.appConfiguration;
    if (appConfiguration == null || !appConfiguration.isComplete) {
      print("Ignoring $message as App Config is null or not complete");
      return null;
    }
    Map data = message['data'] ?? message;
    print("data: $data");
    final alertService = ServiceFactory.alertService(appConfiguration);
    await alertService.processLiteAlert(data);
    await alertService.processPendingAlerts();
  }

  Future<void> _onLaunch(Map<String, dynamic> message) {
    print("onLaunch $message");
    return null;
  }

  Future<void> _onResume(Map<String, dynamic> message) {
    print("onResume $message");
    return null;
  }
}
