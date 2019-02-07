import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/setup_master_proxy_page.dart';
import 'package:proxy_flutter/welcome/welcome.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage({Key key, @required this.appConfiguration}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends State<HomePage> {
  final AppConfiguration appConfiguration;
  bool _showWelcomePages = true;

  ProxyVersion proxyVersion = ProxyVersion.latestVersion();

  _HomePageState(this.appConfiguration) {
    _showWelcomePages = appConfiguration.showWelcomePages;
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcomePages) {
      return Welcome(onWelcomeOver: onWelcomeOver);
    } else {
      return SetupMasterProxyPage(appConfiguration: appConfiguration);
    }
  }

  void onWelcomeOver() {
    setState(() {
      _showWelcomePages = false;
      widget.appConfiguration.showWelcomePages = _showWelcomePages;
    });
  }
}
