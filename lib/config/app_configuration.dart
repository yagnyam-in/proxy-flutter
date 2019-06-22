import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String PROXY_UNIVERSE = "proxyUniverse";

  static AppConfiguration _instance;

  static AppConfiguration instance() => _instance;

  static AppConfiguration setInstance(AppConfiguration appConfig) {
    _instance = appConfig;
    return appConfig;
  }

  final SharedPreferences preferences;
  final FirebaseUser firebaseUser;
  UserEntity appUser;

  AppConfiguration({
    @required this.preferences,
    @required this.firebaseUser,
  }) {
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
    return appUser?.masterProxyId;
  }

  String get proxyUniverse {
    String val = preferences.getString(PROXY_UNIVERSE);
    if (val == null || val.isEmpty) {
      return ProxyUniverse.TEST;
    }
    return val;
  }

  set proxyUniverse(String value) {
    preferences.setString(PROXY_UNIVERSE, value);
  }


  bool get isProductionUniverse {
    return proxyUniverse == ProxyUniverse.PRODUCTION;
  }

  String get displayName {
    return appUser?.name ?? firebaseUser?.displayName;
  }

  String get phoneNumber {
    return appUser?.phone ?? firebaseUser?.phoneNumber;
  }

  String get email {
    return appUser?.email ?? firebaseUser?.email;
  }

}
