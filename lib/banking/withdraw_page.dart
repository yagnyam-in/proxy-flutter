import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/banking/store/deposit_store.dart';
import 'package:proxy_flutter/banking/store/withdrawal_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:url_launcher/url_launcher.dart';

class WithdrawPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String withdrawalId;

  const WithdrawPage({
    Key key,
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.withdrawalId,
  }) : super(key: key);

  @override
  WithdrawPageState createState() {
    return WithdrawPageState(
      appConfiguration: appConfiguration,
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    );
  }
}

class WithdrawPageState extends LoadingSupportState<WithdrawPage> {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String withdrawalId;
  Stream<WithdrawalEntity> _withdrawalStream;

  WithdrawPageState({
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.withdrawalId,
  });

  @override
  void initState() {
    super.initState();
    _withdrawalStream = WithdrawalStore(firebaseUser: appConfiguration.firebaseUser).subscribeForWithdrawal(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.depositEventTitle),
        actions: [
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: new Text(
              localizations.okButtonLabel,
              style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: StreamBuilder<WithdrawalEntity>(
            stream: _withdrawalStream,
            builder: (BuildContext context, AsyncSnapshot<WithdrawalEntity> snapshot) {
              return body(context, localizations, snapshot);
            },
          ),
        ),
      ),
    );
  }

  Widget body(
    BuildContext context,
    ProxyLocalizations localizations,
    AsyncSnapshot<WithdrawalEntity> snapshot,
  ) {
    if (!snapshot.hasData) {
      return _noDepositFound(context);
    }
    ThemeData themeData = Theme.of(context);
    WithdrawalEntity withdrawalEntity = snapshot.data;

    List<Widget> rows = [
      const SizedBox(height: 16.0),
      Icon(withdrawalEntity.icon, size: 64.0),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.amount,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          localizations.amountDisplayMessage(
            currency: Currency.currencySymbol(withdrawalEntity.amount.currency),
            value: withdrawalEntity.amount.value,
          ),
          style: themeData.textTheme.title,
        ),
      ),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.status,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          withdrawalEntity.getStatusAsText(localizations),
          style: themeData.textTheme.title,
        ),
      ),
    ];

    List<Widget> actions = [];
    if (withdrawalEntity.isCancelPossible) {
      actions.add(
        RaisedButton.icon(
          onPressed: () => _cancelWithdrawal(withdrawalEntity),
          icon: Icon(Icons.close),
          label: Text(localizations.cancelButtonLabel),
        ),
      );
    }
    if (actions.isNotEmpty) {
      rows.add(const SizedBox(height: 24.0));
      rows.add(
        ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: actions,
        ),
      );
    }
    return ListView(children: rows);
  }

  Widget _noDepositFound(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.error, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.withdrawalNotFound,
          ),
        ),
        const SizedBox(height: 32.0),
        RaisedButton.icon(
          onPressed: _close,
          icon: Icon(Icons.close),
          label: Text(localizations.closeButtonLabel),
        ),
      ],
    );
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _cancelWithdrawal(WithdrawalEntity withdrawalEntity) {}
}
