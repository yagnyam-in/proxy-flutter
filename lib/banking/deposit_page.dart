import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';

class DepositPage extends StatefulWidget {
  final DepositEntity depositEntity;

  const DepositPage({
    Key key,
    @required this.depositEntity,
  }) : super(key: key);

  @override
  DepositPageState createState() {
    return DepositPageState(
      depositEntity: depositEntity,
    );
  }
}

class DepositPageState extends LoadingSupportState<DepositPage> {
  final DepositEntity depositEntity;

  DepositPageState({
    @required this.depositEntity,
  });

  @override
  void initState() {
    super.initState();
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
          child: FutureBuilder<DepositEntity>(
            future: Future.value(depositEntity),
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
          onPressed: () => _shareDeposit(depositEntity),
          icon: Icon(Icons.share),
          label: Text(localizations.shareDeposit),
        ),
      );
    }
    if (depositEntity.isCancelPossible) {
      actions.add(
        RaisedButton.icon(
          onPressed: () => _cancelDeposit(depositEntity),
          icon: Icon(Icons.close),
          label: Text(localizations.closeButtonLabel),
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
        const SizedBox(height: 8.0),
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

  void _shareDeposit(DepositEntity depositEntity) {

  }

  void _cancelDeposit(DepositEntity depositEntity) {

  }
}
