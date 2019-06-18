
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';

class BankingHome extends StatefulWidget {
  final AppConfiguration appConfiguration;

  BankingHome(this.appConfiguration, {Key key}) : super(key: key) {
    assert(appConfiguration != null);
  }

  @override
  BankingHomeState createState() {
    return BankingHomeState(appConfiguration);
  }

}

class BankingHomeState extends State<BankingHome> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BankingHomeState(this.appConfiguration);

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Index 0: Home',
      style: optionStyle,
    ),
    Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.bankingTitle),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            title: Text(localizations.accountsPageTitle),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            title: Text(localizations.eventsPageTitle),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            title: Text(localizations.profilePageTitle),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
