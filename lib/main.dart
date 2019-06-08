import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:proxy_flutter/app_state_container.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/login_page.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(ProxyApp());

class ProxyApp extends StatefulWidget {
  @override
  State<ProxyApp> createState() {
    return ProxyAppState();
  }
}

class ProxyAppState extends State<ProxyApp> {
  Future<FirebaseUser> _firebaseUserFuture;
  Future<SharedPreferences> _sharedPreferences;

  @override
  void initState() {
    super.initState();
    _firebaseUserFuture = FirebaseAuth.instance.currentUser();
    _sharedPreferences = SharedPreferences.getInstance();
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
        child: FutureBuilder(
          future: _firebaseUserFuture,
          builder: _body,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<FirebaseUser> user) {
    if (LOADING_STATES.contains(user.connectionState)) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (user.hasError) {
      return Center(
        child: Text(
          ProxyLocalizations.of(context).startupError,
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      );
    } else if (!user.hasData) {
      return FutureBuilder(
        future: _sharedPreferences,
        builder: _loginPage,
      );
    } else {
      return FutureBuilder(
        future: _sharedPreferences,
        builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
          return _homePage(context, user.data, snapshot);
        },
      );
    }
  }

  void _loginCallback(FirebaseUser firebaseUser) {
    setState(() {
      this._firebaseUserFuture = Future.value(firebaseUser);
    });
  }

  Widget _loginPage(BuildContext context, AsyncSnapshot<SharedPreferences> preferences) {
    if (LOADING_STATES.contains(preferences.connectionState)) {
      return LoadingWidget();
    } else if (preferences.hasError) {
      return Center(
        child: Text(
          ProxyLocalizations.of(context).startupError,
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      );
    } else {
      return LoginPage(
        sharedPreferences: preferences.data,
        loginCallback: _loginCallback,
      );
    }
  }

  Widget _homePage(BuildContext context, FirebaseUser firebaseUser, AsyncSnapshot<SharedPreferences> preferences) {
    if (LOADING_STATES.contains(preferences.connectionState)) {
      return LoadingWidget();
    } else if (preferences.hasError) {
      return Center(
        child: Text(
          ProxyLocalizations.of(context).startupError,
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      );
    } else {
      print('firebaseUser: $firebaseUser');
      AppConfiguration.setInstance(
        AppConfiguration(
          preferences: preferences.data,
          firebaseUser: firebaseUser,
        ),
      );
      return HomePage(
        appConfiguration: AppConfiguration.instance(),
      );
    }
  }

  static const Set<ConnectionState> LOADING_STATES = {
    ConnectionState.none,
    ConnectionState.waiting,
    ConnectionState.active,
  };
}
