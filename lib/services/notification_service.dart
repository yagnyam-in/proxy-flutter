import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class NotificationService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyCentralUrl;
  final HttpClientFactory httpClientFactory;
  final MessageSigningService messageSigningService;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _started = false;

  NotificationService({
    String proxyCentralUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageSigningService,
  })  : proxyCentralUrl = proxyCentralUrl ?? "https://proxy-cs.appspot.com/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyCentralUrl));
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
    print("New FCM Token $newToken");
    if (newToken != null) {
      List<ProxyKey> outdatedProxies = await ServiceFactory.proxyKeyRepo().fetchProxiesWithoutFcmToken(newToken);
      print('Got ${outdatedProxies.length} proxies to update');
      outdatedProxies.forEach((key) => updateToken(key, newToken));
    }
  }

  void updateToken(ProxyKey proxyKey, String newToken) async {
    print("Updating FCM Token for ${proxyKey.id}");
    ProxyCustomerUpdateRequest request = new ProxyCustomerUpdateRequest(
      requestId: uuidFactory.v4(),
      proxyId: proxyKey.id,
      gcmToken: newToken,
    );
    SignedMessage<ProxyCustomerUpdateRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    print("Sending $signedRequestJson to $proxyCentralUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyCentralUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyCentralUrl");
    ServiceFactory.proxyKeyRepo().updateFcmToken(proxyKey.id, newToken);
  }

  void tokenRefreshFailure(error) {
    print("FCM token refresh failed with error $error");
  }

  Future<void> onMessage(Map<String, dynamic> message) {
    print("onMessage $message");
    Map<dynamic, dynamic> data = message['data'];
    print('data: $data');
    String type = data != null ? data['alertType'] : null;
    print('type: $type');
    if (type == AccountUpdatedAlert.ALERT_TYPE) {
      AccountUpdatedAlert alert = AccountUpdatedAlert.fromJson(data);
      ServiceFactory.bankingService().refreshAccount(alert.proxyAccountId);
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