import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:proxy_flutter/app_state_container.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(ProxyApp());

class ProxyApp extends StatefulWidget {
  @override
  State<ProxyApp> createState() {
    return ProxyAppState();
  }
}

Future<Uri> _retrieveDynamicLink() async {
  final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.retrieveDynamicLink();
  return data?.link;
}

enum _ProxyAppStatus { loading, error, ready }

class ProxyAppState extends State<ProxyApp> with WidgetsBindingObserver {
  AppConfiguration configuration;
  _ProxyAppStatus _appStatus = _ProxyAppStatus.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchAppConfiguration();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState");
    if (state == AppLifecycleState.resumed) {
      _retrieveDynamicLink().then((u) {
        print("deeplink:$u");
      });
    }
  }

  void updateConfiguration(AppConfiguration value) {
    setState(() {
      _appStatus = _ProxyAppStatus.ready;
      this.configuration = value;
    });
  }

  void errorLoadingConfiguration(e) {
    setState(() {
      _appStatus = _ProxyAppStatus.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // locale: const Locale('nl', 'NL'),
        onGenerateTitle: (BuildContext context) => ProxyLocalizations.of(context).title,
        localizationsDelegates: [
          const ProxyLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', 'US'),
          const Locale('nl', 'NL'),
          const Locale('te', 'IN'),
        ],
        home: new AppStateContainer(
          child: homePage(context),
        ));
  }

  Widget homePage(BuildContext context) {
    if (_appStatus == _ProxyAppStatus.error) {
      return Center(
        child: Text(
          ProxyLocalizations.of(context).startupError,
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      );
    } else if (_appStatus == _ProxyAppStatus.ready) {
      return HomePage(appConfiguration: configuration);
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  void fetchAppConfiguration() async {
    SharedPreferences.getInstance().then((preferences) {
      updateConfiguration(AppConfiguration(preferences: preferences));
    }).catchError((e) {
      errorLoadingConfiguration(e);
    });
  }
}
