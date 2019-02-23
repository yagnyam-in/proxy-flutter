import 'package:flutter/foundation.dart';
import 'package:proxy_core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfiguration {
  static const String ShowWelcomePages = "showWelcomePagesV0";
  static const String TermsAndConditionsAccepted = "termsAndConditionsAcceptedV0";
  static const String MasterProxyId = "masterProxyId";

  final SharedPreferences preferences;

  AppConfiguration({@required this.preferences}) {
    assert(preferences != null);
  }

  bool get showWelcomePages {
    bool show = preferences.getBool(ShowWelcomePages);
    return show == null || show;
  }

  set showWelcomePages(bool value) {
    preferences.setBool(ShowWelcomePages, value);
  }

  bool get termsAndConditionsAccepted {
    bool show = preferences.getBool(TermsAndConditionsAccepted);
    return show != null && show;
  }

  set termsAndConditionsAccepted(bool value) {
    preferences.setBool(TermsAndConditionsAccepted, value);
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
}
