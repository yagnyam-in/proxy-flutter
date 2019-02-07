import 'package:flutter/foundation.dart';
import 'package:proxy_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";

  final SharedPreferences preferences;
  final ProxyId masterProxyId;

  AppConfiguration({@required this.preferences, this.masterProxyId}) {
    assert(preferences != null);
  }

  void persist() {
    preferences.setString('masterProxyId', masterProxyId.toString());
  }

  bool get showWelcomePages {
    bool show = preferences.getBool(ShowWelcomePages);
    return show == null || show;
  }

  set showWelcomePages(bool value) {
    preferences.setBool(ShowWelcomePages, value);
  }
}
