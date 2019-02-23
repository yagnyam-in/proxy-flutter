import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/setup_master_proxy_page.dart';
import 'package:proxy_flutter/terms_and_conditions.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage({Key key, @required this.appConfiguration}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends State<HomePage> {
  final AppConfiguration appConfiguration;
  bool _showWelcomePages = true;
  bool _termsAndConditionsAccepted = false;
  bool _masterProxySetup = false;

  ProxyVersion proxyVersion = ProxyVersion.latestVersion();

  _HomePageState(this.appConfiguration) {
    _showWelcomePages = appConfiguration.showWelcomePages;
    _termsAndConditionsAccepted = appConfiguration.termsAndConditionsAccepted;
    _masterProxySetup = appConfiguration.masterProxyId != null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_termsAndConditionsAccepted) {
      return TermsAndConditionsPage(
        appConfiguration: appConfiguration,
        termsAndConditionsAcceptedCallback: termsAndConditionsAcceptedCallback,
      );
    } else {
      return SetupMasterProxyPage(
        appConfiguration: appConfiguration,
        setupMasterProxyCallback: setupMasterProxyCallback,
      );
    }
  }

  void onWelcomeOver() {
    setState(() {
      _showWelcomePages = false;
      widget.appConfiguration.showWelcomePages = _showWelcomePages;
    });
  }

  void termsAndConditionsAcceptedCallback() {
    setState(() {
      _termsAndConditionsAccepted = true;
      widget.appConfiguration.termsAndConditionsAccepted = _termsAndConditionsAccepted;
    });
  }

  void setupMasterProxyCallback(ProxyId proxyId) {
    setState(() {
      _masterProxySetup = true;
      widget.appConfiguration.masterProxyId = proxyId;
    });
  }

}
