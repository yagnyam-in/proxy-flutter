import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/db/deposit_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:url_launcher/url_launcher.dart';

class DepositPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String depositId;

  const DepositPage({
    Key key,
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.depositId,
  }) : super(key: key);

  @override
  DepositPageState createState() {
    return DepositPageState(
      appConfiguration: appConfiguration,
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    );
  }
}

class DepositPageState extends LoadingSupportState<DepositPage> {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String depositId;
  Stream<DepositEntity> _depositStream;

  DepositPageState({
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.depositId,
  });

  @override
  void initState() {
    super.initState();
    _depositStream = DepositStore(appConfiguration).subscribeForDeposit(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
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
          child: StreamBuilder<DepositEntity>(
            stream: _depositStream,
            builder: (BuildContext context, AsyncSnapshot<DepositEntity> snapshot) {
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
    AsyncSnapshot<DepositEntity> snapshot,
  ) {
    if (!snapshot.hasData) {
      return _noDepositFound(context);
    }
    ThemeData themeData = Theme.of(context);
    DepositEntity depositEntity = snapshot.data;

    List<Widget> rows = [
      const SizedBox(height: 16.0),
      Icon(depositEntity.icon, size: 64.0),
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
            currency: Currency.currencySymbol(depositEntity.amount.currency),
            value: depositEntity.amount.value,
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
          depositEntity.getStatusAsText(localizations),
          style: themeData.textTheme.title,
        ),
      ),
    ];

    List<Widget> actions = [];
    if (depositEntity.isDepositPossible) {
      actions.add(
        RaisedButton.icon(
          onPressed: () => _pay(depositEntity),
          icon: Icon(Icons.open_in_browser),
          label: Text(localizations.payButtonLabel),
        ),
      );
    }
    if (depositEntity.isCancelPossible) {
      actions.add(
        RaisedButton.icon(
          onPressed: () => _cancelDeposit(depositEntity),
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
            localizations.depositNotFound,
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

  Future<void> _pay(DepositEntity depositEntity) async {
    if (await canLaunch(depositEntity.depositLink)) {
      await launch(depositEntity.depositLink);
    } else {
      print("Unable to Launch ${depositEntity.depositLink}");
    }
  }

  void _cancelDeposit(DepositEntity depositEntity) {}
}
