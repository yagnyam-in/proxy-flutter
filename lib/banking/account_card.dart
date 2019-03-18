import 'package:flutter/material.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';

class AccountCard extends StatelessWidget {
  final ProxyAccountEntity account;

  const AccountCard({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(account);
    return makeCard(context);
  }

  Widget makeCard(BuildContext context) {
    return Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          // color: Color.fromRGBO(64, 75, 96, .9),
        ),
        child: makeListTile(context),
      ),
    );
  }

  String get accountName => account.accountName ?? account.accountId;
  
  String get bankName => account.bankName ?? account.bankId; 

  Icon _userIcon(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Icon(
      Icons.account_balance_wallet,
      color: themeData.primaryColor,
      size: 30.0,
    );
  }

  Widget makeListTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        accountName,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          bankName,
        ),
      ),
      trailing: _userIcon(context),
    );
  }
}
