import 'package:flutter/cupertino.dart';
import 'package:promo/banking/events_page.dart';
import 'package:promo/banking/proxy_accounts_page.dart';
import 'package:promo/banking/receiving_accounts_page.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/settings_page.dart';

import 'home_page_navigation.dart';

class BankingHome extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const BankingHome(this.appConfiguration, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BankingHomeState(appConfiguration);
  }
}

class _BankingHomeState extends State<BankingHome> {
  final AppConfiguration appConfiguration;

  HomePage _homePage = HomePage.ProxyAccountsPage;

  _BankingHomeState(this.appConfiguration);

  @override
  Widget build(BuildContext context) {
    switch (_homePage) {
      case HomePage.ProxyAccountsPage:
        return ProxyAccountsPage(
          appConfiguration,
          changeHomePage: changeHomePage,
        );
      case HomePage.EventsPage:
        return EventsPage(
          appConfiguration,
          changeHomePage: changeHomePage,
        );
      case HomePage.BankAccountsPage:
        return ReceivingAccountsPage.manage(
          appConfiguration,
          changeHomePage: changeHomePage,
        );
      case HomePage.SettingsPage:
        return SettingsPage(
          appConfiguration,
          changeHomePage: changeHomePage,
        );
      default:
        return ProxyAccountsPage(
          appConfiguration,
          changeHomePage: changeHomePage,
        );
    }
  }

  void changeHomePage(HomePage homePage) {
    setState(() {
      _homePage = homePage;
    });
  }
}
