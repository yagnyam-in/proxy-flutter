import 'package:flutter/material.dart';
import 'package:promo/banking/db/deposit_store.dart';
import 'package:promo/banking/model/deposit_entity.dart';
import 'package:promo/banking/services/banking_service_factory.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/action_menu_item.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:url_launcher/url_launcher.dart';

class DepositPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String depositInternalId;
  final DepositEntity deposit;

  DepositPage(
    this.appConfiguration, {
    Key key,
    String depositInternalId,
    this.deposit,
  })  : this.depositInternalId = depositInternalId ?? deposit?.internalId,
        super(key: key) {
    assert(this.depositInternalId != null, "depositInternalId can't be null");
  }

  @override
  DepositPageState createState() {
    return DepositPageState(
      appConfiguration: appConfiguration,
      depositInternalId: depositInternalId,
    );
  }
}

class DepositPageState extends LoadingSupportState<DepositPage> {
  static const String CANCEL = "cancel";

  final AppConfiguration appConfiguration;
  final String depositInternalId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<DepositEntity> _depositStream;
  bool loading = false;

  DepositPageState({
    @required this.appConfiguration,
    @required this.depositInternalId,
  });

  @override
  void initState() {
    super.initState();
    _depositStream = DepositStore(appConfiguration).subscribeByInternalId(depositInternalId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<ActionMenuItem> actions(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      ActionMenuItem(title: localizations.cancelDepositTooltip, icon: Icons.cancel, action: CANCEL),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.depositEventTitle + appConfiguration.proxyUniverseSuffix),
        actions: <Widget>[
          PopupMenuButton<ActionMenuItem>(
            onSelected: (action) => _performAction(context, action),
            itemBuilder: (BuildContext context) {
              return actions(context).map((ActionMenuItem choice) {
                return PopupMenuItem<ActionMenuItem>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: streamBuilder(
            initialData: widget.deposit,
            stream: _depositStream,
            builder: body,
            emptyWidget: _noDepositFound(context),
          ),
        ),
      ),
    );
  }

  Widget body(
    BuildContext context,
    DepositEntity depositEntity,
  ) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

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

  void _performAction(BuildContext context, ActionMenuItem action) {
    if (action.action == CANCEL) {
      _cancelDeposit(context);
    } else {
      print("Unknown action $action");
    }
  }

  void showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _cancelDeposit(BuildContext context) async {
    final depositEntity = await DepositStore(appConfiguration).fetchByInternalId(depositInternalId);
    if (depositEntity == null || !depositEntity.isCancelPossible) {
      showMessage(ProxyLocalizations.of(context).cancelNotPossible);
      return Future.value(null);
    }
    return BankingServiceFactory.depositService(appConfiguration).cancelDeposit(depositEntity);
  }
}
