import 'package:flutter/material.dart';
import 'package:promo/banking/db/withdrawal_store.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/action_menu_item.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';

class WithdrawalPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final WithdrawalEntity withdrawal;
  final String withdrawalInternalId;

  WithdrawalPage(
    this.appConfiguration, {
    Key key,
    this.withdrawal,
    String withdrawalInternalId,
  })  : this.withdrawalInternalId = withdrawalInternalId ?? withdrawal?.internalId,
        super(key: key);

  @override
  WithdrawalPageState createState() {
    return WithdrawalPageState(
      appConfiguration: appConfiguration,
      withdrawalInternalId: withdrawalInternalId,
    );
  }
}

class WithdrawalPageState extends LoadingSupportState<WithdrawalPage> {
  static const String CANCEL = "cancel";

  final AppConfiguration appConfiguration;
  final String withdrawalInternalId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<WithdrawalEntity> _withdrawalStream;
  bool loading = false;

  WithdrawalPageState({
    @required this.appConfiguration,
    @required this.withdrawalInternalId,
  });

  @override
  void initState() {
    super.initState();
    _withdrawalStream = WithdrawalStore(appConfiguration).subscribeByInternalId(withdrawalInternalId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<ActionMenuItem> actions(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      ActionMenuItem(title: localizations.cancelPaymentTooltip, icon: Icons.cancel, action: CANCEL),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.withdrawalEventTitle + appConfiguration.proxyUniverseSuffix),
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

    return ListView(
      children: [
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
      ],
    );
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
      ],
    );
  }

  void _performAction(BuildContext context, ActionMenuItem action) {
    if (action.action == CANCEL) {
      _cancelWithdrawal(context);
    } else {
      print("Unknown action $action");
    }
  }

  void _cancelWithdrawal(BuildContext context) async {
    final withdrawal = await WithdrawalStore(appConfiguration).fetchByInternalId(withdrawalInternalId);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (withdrawal == null || !withdrawal.isCancelPossible) {
      showMessage(localizations.cancelNotPossible);
      return;
    }
    showMessage(localizations.notYetImplemented);
  }

  void showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
