import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';

enum HomePage {
  AccountsPage,
  EventsPage,
  ProfilePage,
}

typedef void ChangeHomePage(HomePage homePage);

class _BottomNavigationBar extends StatefulWidget {
  final ChangeHomePage changeHomePage;
  final HomePage homePage;

  const _BottomNavigationBar(this.changeHomePage, this.homePage, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _BottomNavigationBarState(changeHomePage, homePage);
  }
}

class _BottomNavigationBarState extends State<_BottomNavigationBar> {
  final ChangeHomePage changeHomePage;
  final HomePage homePage;

  int _selectedIndex;

  _BottomNavigationBarState(this.changeHomePage, this.homePage) {
    switch (homePage) {
      case HomePage.AccountsPage:
        _selectedIndex = 0;
        break;
      case HomePage.EventsPage:
        _selectedIndex = 1;
        break;
      case HomePage.ProfilePage:
        _selectedIndex = 2;
        break;
      default:
        _selectedIndex = 0;
        break;
    }
  }

  void _onItemTapped(int index) {
    print("_onItemTapped($index)");
    setState(() {
      _selectedIndex = index;
    });
    switch (_selectedIndex) {
      case 0:
        changeHomePage(HomePage.AccountsPage);
        break;
      case 1:
        changeHomePage(HomePage.EventsPage);
        break;
      case 2:
        changeHomePage(HomePage.ProfilePage);
        break;
      default:
        print("HomePage for $_selectedIndex is not handled");
        changeHomePage(HomePage.AccountsPage);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return BottomNavigationBar(
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
      onTap: (index) {
        _onItemTapped(index);
      },
    );
  }
}

mixin HomePageNavigation {
  Widget navigationBar(BuildContext context, HomePage homePage, {@required ChangeHomePage changeHomePage}) {
    return _BottomNavigationBar(changeHomePage, homePage);
  }
}
