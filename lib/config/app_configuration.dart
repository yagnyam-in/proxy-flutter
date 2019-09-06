import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:quiver/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PASSPHRASE_KEY = "passPhrase";
  static const String DEVICE_ID = "deviceId";

  final SharedPreferences preferences;
  final FirebaseUser firebaseUser;
  UserEntity appUser;
  AccountEntity account;
  String passPhrase;
  String proxyUniverse;
  String deviceId;

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
    this.deviceId,
  }) {
    assert(preferences != null);
  }

  AppConfiguration copy({
    FirebaseUser firebaseUser,
    UserEntity appUser,
    AccountEntity account,
    String passPhrase,
    String proxyUniverse,
    String deviceId,
  }) {
    return AppConfiguration(
      preferences: preferences,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      appUser: appUser ?? this.appUser,
      account: account ?? this.account,
      passPhrase: passPhrase ?? this.passPhrase,
      proxyUniverse: proxyUniverse ?? this.proxyUniverse,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is AppConfiguration) {
      return this.firebaseUser == other.firebaseUser &&
          this.appUser == other.appUser &&
          this.account == other.account &&
          this.passPhrase == other.passPhrase &&
          this.proxyUniverse == other.proxyUniverse &&
          this.deviceId == other.deviceId;
    }
    return false;
  }

  @override
  int get hashCode {
    return account?.accountId.hashCode ?? firebaseUser?.uid.hashCode ?? 0;
  }

  @override
  String toString() {
    return "AppConfiguration(firebaseUser: ${firebaseUser?.uid}, email: $email, account: $accountId)";
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
    return proxyUniverse == null || proxyUniverse == ProxyUniverse.PRODUCTION;
  }

  String get displayName {
    return account?.name ?? appUser?.name ?? firebaseUser?.displayName;
  }

  String get phoneNumber {
    return account?.phone ?? appUser?.phone ?? firebaseUser?.phoneNumber;
  }

  String get email {
    return account?.email ?? appUser?.email ?? firebaseUser?.email;
  }

  bool get isComplete {
    return firebaseUser != null && appUser != null && account != null && passPhrase != null;
  }

  Future<void> persist() async {
    Future.wait([
      _storePassPhrase(passPhrase),
      storeProxyUniverse(proxyUniverse),
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

  static Future<String> fetchDeviceId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String deviceId = preferences.getString(DEVICE_ID);
    if (isNotEmpty(deviceId)) {
      return deviceId;
    } else {
      deviceId = Uuid().v4();
      preferences.setString(DEVICE_ID, deviceId);
      return deviceId;
    }
  }

  static Future<void> storeProxyUniverse(String value) async {
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
