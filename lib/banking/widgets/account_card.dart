import 'package:flutter/material.dart';
import 'package:promo/banking/model/proxy_account_entity.dart';
import 'package:proxy_messages/banking.dart';

class AccountCard extends StatelessWidget {
  final ProxyAccountEntity account;

  const AccountCard({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(account);
    return Card(
      elevation: 4.0,
      margin: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
            // color: Color.fromRGBO(64, 75, 96, .9),
            ),
        child: makeListTile(context),
      ),
    );
  }

  String get accountName => account.validAccountName;

  String get bankName => account.validBankName;

  String get balance => '${account.balance.value} ${Currency.currencySymbol(account.balance.currency)}';

  Widget makeListTile(BuildContext context) {
    ThemeData themeData = Theme.of(context);
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
      trailing: Text(
        balance,
        style: themeData.textTheme.title,
      ),
    );
  }
}
