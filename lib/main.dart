import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:proxy_flutter/app_state_container.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/account_store.dart';
import 'package:proxy_flutter/db/user_store.dart';
import 'package:proxy_flutter/home_page.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/login_page.dart';
import 'package:proxy_flutter/manage_account_page.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/flat_button_with_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(ProxyApp());

class ProxyApp extends StatefulWidget {
  @override
  State<ProxyApp> createState() {
    return ProxyAppState();
  }
}

class ProxyAppState extends LoadingSupportState<ProxyApp> {
  Future<AppConfiguration> _appConfigurationFuture;

  @override
  void initState() {
    super.initState();
    _appConfigurationFuture = _fetchAppConfiguration();
  }

  Future<AppConfiguration> _fetchAppConfiguration() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();
    UserEntity appUser;
    AccountEntity account;
    String passPhrase = await AppConfiguration.fetchPassPhrase();
    if (firebaseUser != null) {
      appUser = await UserStore.forUser(firebaseUser).fetchUser();
      print("Got App User => $appUser");
    }
    if (appUser?.accountId != null) {
      account = await AccountStore().fetchAccount(appUser.accountId);
      print("Got Account => $account");
    }
    if (account != null) {
      bool isPassPhraseValid = await AccountService(
        firebaseUser: firebaseUser,
        appUser: appUser,
      ).validateEncryptionKey(
        account: account,
        encryptionKey: passPhrase,
      );
      if (!isPassPhraseValid) {
        passPhrase = null;
      }
    }
    return AppConfiguration(
        preferences: sharedPreferences,
        firebaseUser: firebaseUser,
        appUser: appUser,
        account: account,
        passPhrase: passPhrase);
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
        child: futureBuilder(future: _appConfigurationFuture, builder: _body, errorWidget: _errorWidget(context)),
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Unexpected Error"),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 32.0),
            Center(child: Text("Something went wrong")),
            const SizedBox(height: 32.0),
            FlatButtonWithIcon(
              icon: Icon(Icons.refresh),
              label: Text("Retry"),
              onPressed: () => setState(() => _appConfigurationFuture = _fetchAppConfiguration()),
            )
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppConfiguration appConfiguration) {
    if (appConfiguration.firebaseUser == null) {
      return LoginPage(
        appConfiguration: appConfiguration,
        loginCallback: _updateAppConfiguration,
      );
    } else if (appConfiguration.appUser == null ||
        appConfiguration.account == null ||
        appConfiguration.passPhrase == null) {
      return ManageAccountPage(
        appConfiguration,
        manageAccountCallback: _updateAppConfiguration,
      );
    } else {
      AppConfiguration.setInstance(appConfiguration);
      return HomePage(
        appConfiguration: AppConfiguration.instance(),
      );
    }
  }

  void _updateAppConfiguration(AppConfiguration appConfiguration) {
    setState(() {
      AppConfiguration.setInstance(appConfiguration);
      _appConfigurationFuture = _fetchAppConfiguration();
    });
  }
}
