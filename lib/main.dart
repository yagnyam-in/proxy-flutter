import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:proxy_flutter/choose_proxy_universe_page.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/flat_button_with_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_or_recover_account_page.dart';
import 'services/service_factory.dart';
import 'welcome_page.dart';

void main() {
  Crashlytics.instance.enableInDevMode = true;
  FlutterError.onError = (FlutterErrorDetails details) {
    Crashlytics.instance.onError(details);
  };
  runApp(ProxyApp());
}

class ProxyApp extends StatefulWidget {
  @override
  State<ProxyApp> createState() {
    return ProxyAppState();
  }
}

class ProxyAppState extends LoadingSupportState<ProxyApp> {
  Stream<AppConfiguration> _appConfigurationStream;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().warmUpBackends();
    ServiceFactory.bootService().subscribeForAlerts();
    _appConfigurationStream = AppConfigurationBloc.instance.appConfigurationStream;
    AppConfigurationBloc.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // locale: const Locale('nl', 'NL'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
      home: streamBuilder(
        stream: _appConfigurationStream,
        builder: _body,
        errorWidget: _errorWidget(context),
        name: 'AppConfiguration',
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    // This can be null
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.unexpectedError ?? 'Unexpected Error'),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 32.0),
            Center(child: Text(localizations?.somethingWentWrong ?? 'Something went wrong')),
            const SizedBox(height: 32.0),
            FlatButtonWithIcon(
              icon: Icon(Icons.refresh),
              label: Text(localizations?.retry ?? 'Retry'),
              onPressed: _recoverFromFailure,
            )
          ],
        ),
      ),
    );
  }

  void _recoverFromFailure() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.clear();
    } catch (e) {
      print("Failed to clear shared preferences");
    }
    try {
      await FlutterSecureStorage().deleteAll();
    } catch (e) {
      print("Failed to clear secure storage");
    }
    AppConfigurationBloc.instance.refresh();
  }

  Widget _body(BuildContext context, AppConfiguration appConfiguration) {
    print("Painting Main Page with appConfiguration $appConfiguration");
    if (appConfiguration.firebaseUser == null || appConfiguration.appUser == null) {
      print("Returning Login Page");
      return WelcomePage(
        appConfiguration,
        key: ValueKey(appConfiguration),
      );
    } else if (appConfiguration.account == null ||
        appConfiguration.passPhrase == null ||
        appConfiguration.account.masterProxyId == null) {
      print("Returning Account Setup Page");
      return CreateOrRecoverAccount(
        appConfiguration,
        key: ValueKey(appConfiguration),
      );
    } else if (appConfiguration.proxyUniverse == null) {
      print("Returning Choose Proxy Universe Page");
      return ChooseProxyUniverse(
        appConfiguration,
        key: ValueKey(appConfiguration),
      );
    } else {
      print("Returning Home Page");
      return HomePage(
        appConfiguration,
        key: ValueKey(appConfiguration),
      );
    }
  }
}
