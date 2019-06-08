import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:proxy_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String MasterProxyId = "masterProxyId";
  static const String CustomerName = "customerName";

  static AppConfiguration _instance;
  static AppConfiguration instance() => _instance;
  static AppConfiguration setInstance(AppConfiguration appConfig) {
    _instance = appConfig;
    return appConfig;
  }

  final SharedPreferences preferences;
  final FirebaseUser firebaseUser;

  AppConfiguration({@required this.preferences, @required this.firebaseUser}) {
    assert(preferences != null);
    assert(firebaseUser != null);
  }

  bool get showWelcomePages {
    bool show = preferences.getBool(ShowWelcomePages);
    return show == null || show;
  }

  set showWelcomePages(bool value) {
    preferences.setBool(ShowWelcomePages, value);
  }

  ProxyId get masterProxyId {
    String proxyId = preferences.getString(MasterProxyId);
    if (proxyId != null && proxyId.isNotEmpty) {
      return ProxyId.fromUniqueId(proxyId);
    } else {
      return null;
    }
  }

  set masterProxyId(ProxyId proxyId) {
    preferences.setString(MasterProxyId, proxyId.uniqueId);
  }

  String get customerName {
    return preferences.getString(CustomerName);
  }

  set customerName(String value) {
    preferences.setString(CustomerName, value);
  }
}
