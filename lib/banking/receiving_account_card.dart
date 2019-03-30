import 'package:flutter/material.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_messages/banking.dart';

class ReceivingAccountCard extends StatelessWidget {
  final ReceivingAccountEntity account;

  const ReceivingAccountCard({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(account);
    return makeCard(context);
  }

  Widget makeCard(BuildContext context) {
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

  Widget makeListTile(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        '${account.bank} - ${account.proxyUniverse}',
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          account.accountNumber,
        ),
      ),
      trailing: Text(
        Currency.currencySymbol(account.currency),
        style: themeData.textTheme.title,
      ),
    );
  }
}
