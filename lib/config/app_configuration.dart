import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:quiver/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PASSPHRASE_KEY = "passPhrase";

  final SharedPreferences preferences;
  final FirebaseUser firebaseUser;
  UserEntity appUser;
  AccountEntity account;
  String passPhrase;
  String proxyUniverse;

  String get proxyUniverseSuffix {
    if (proxyUniverse == ProxyUniverse.PRODUCTION) {
      return "";
    } else {
      return " [T]";
    }
  }

  AppConfiguration({
    @required this.preferences,
    this.firebaseUser,
    this.appUser,
    this.account,
    this.passPhrase,
    this.proxyUniverse,
  }) {
    assert(preferences != null);
    if (isBlank(proxyUniverse)) {
      proxyUniverse = ProxyUniverse.PRODUCTION;
    }
  }

  AppConfiguration copy({
    FirebaseUser firebaseUser,
    UserEntity appUser,
    AccountEntity account,
    String passPhrase,
    String proxyUniverse,
  }) {
    return AppConfiguration(
      preferences: preferences,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      appUser: appUser ?? this.appUser,
      account: account ?? this.account,
      passPhrase: passPhrase ?? this.passPhrase,
      proxyUniverse: proxyUniverse ?? this.proxyUniverse,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is AppConfiguration) {
      return this.firebaseUser == other.firebaseUser &&
          this.appUser == other.appUser &&
          this.account == other.account &&
          this.passPhrase == other.passPhrase &&
          this.proxyUniverse == other.proxyUniverse;
    }
    return false;
  }

  @override
  int get hashCode {
    return account?.accountId.hashCode ?? firebaseUser?.uid.hashCode ?? 0;
  }

  @override
  String toString() {
    return {
      'firebaseUser': firebaseUser?.uid,
      'appUser': appUser?.email,
      'account': account?.accountId,
      'proxyUniverse': proxyUniverse,
    }.toString();
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

  Future<void> persist() async {
    Future.wait([
      _storePassPhrase(passPhrase),
      _storeProxyUniverse(proxyUniverse),
    ]);
  }

  static Future<String> fetchPassPhrase() async {
    try {
      return await FlutterSecureStorage().read(key: PASSPHRASE_KEY);
    } catch (e, t) {
      print('Error fetching $PASSPHRASE_KEY: $t');
    }
    return null;
  }

  static Future<void> _storePassPhrase(String value) async {
    try {
      if (value != null) {
        return FlutterSecureStorage().write(key: PASSPHRASE_KEY, value: value);
      } else {
        return FlutterSecureStorage().delete(key: PASSPHRASE_KEY);
      }
    } catch (e, t) {
      print('Error storing $PASSPHRASE_KEY: $t');
    }
  }

  static Future<String> fetchProxyUniverse() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      return preferences.getString(PROXY_UNIVERSE);
    } catch (e, t) {
      print('Error fetching $PROXY_UNIVERSE: $t');
    }
    return null;
  }

  static Future<void> _storeProxyUniverse(String value) async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      if (value != null) {
        preferences.setString(PROXY_UNIVERSE, value);
      } else {
        preferences.remove(PROXY_UNIVERSE);
      }
    } catch (e, t) {
      print('Error storing $PROXY_UNIVERSE: $t');
    }
  }
}
