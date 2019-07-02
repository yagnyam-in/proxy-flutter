import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PASSPHRASE_KEY = "passPhrase";

  static AppConfiguration _instance;

  static AppConfiguration instance() => _instance;

  static AppConfiguration setInstance(AppConfiguration appConfig) {
    _instance = appConfig;
    return appConfig;
  }

  final SharedPreferences preferences;
  final FirebaseUser firebaseUser;
  UserEntity appUser;
  AccountEntity account;
  String passPhrase;

  AppConfiguration({
    @required this.preferences,
    this.firebaseUser,
    this.appUser,
    this.account,
    this.passPhrase,
  }) {
    assert(preferences != null);
  }

  AppConfiguration copy({
    FirebaseUser firebaseUser,
    UserEntity appUser,
    AccountEntity account,
    String passPhrase,
  }) {
    return AppConfiguration(
      preferences: preferences,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      appUser: appUser ?? this.appUser,
      account: account ?? this.account,
      passPhrase: passPhrase ?? this.passPhrase,
    );
  }

  String get accountId {
    return appUser?.accountId;
  }

  bool get showWelcomePages {
    bool show = preferences.getBool(ShowWelcomePages);
    return show == null || show;
  }

  set showWelcomePages(bool value) {
    preferences.setBool(ShowWelcomePages, value);
  }

  ProxyId get masterProxyId {
    return account?.masterProxyId;
  }

  String get proxyUniverse {
    String val = preferences.getString(PROXY_UNIVERSE);
    if (val == null || val.isEmpty) {
      return ProxyUniverse.PRODUCTION;
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

  bool get isComplete {
    return firebaseUser != null && appUser != null && account != null && passPhrase != null;
  }

  static Future<String> fetchPassPhrase() async {
    try {
      return await FlutterSecureStorage().read(key: PASSPHRASE_KEY);
    } catch (e, t) {
      print('Error getting $PASSPHRASE_KEY: $t');
    }
    return null;
  }

  static Future<void> storePassPhrase(String value) {
    if (value != null) {
      return FlutterSecureStorage().write(key: PASSPHRASE_KEY, value: value);
    } else {
      return FlutterSecureStorage().delete(key: PASSPHRASE_KEY);
    }
  }
}
