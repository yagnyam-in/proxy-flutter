import 'package:flutter/material.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/banking/db/payment_encashment_store.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/action_menu_item.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';

class PaymentEncashmentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final String paymentEncashmentId;
  final PaymentEncashmentEntity paymentEncashment;

  const PaymentEncashmentPage(
    this.appConfiguration, {
    Key key,
    @required this.proxyUniverse,
    @required this.paymentEncashmentId,
    @required this.paymentAuthorizationId,
    this.paymentEncashment,
  }) : super(key: key);

  factory PaymentEncashmentPage.forPaymentEncashment(
      AppConfiguration appConfiguration, PaymentEncashmentEntity paymentEncashment,
      {Key key}) {
    return PaymentEncashmentPage(
      appConfiguration,
      key: key,
      proxyUniverse: paymentEncashment.proxyUniverse,
      paymentAuthorizationId: paymentEncashment.paymentAuthorizationId,
      paymentEncashmentId: paymentEncashment.paymentEncashmentId,
      paymentEncashment: paymentEncashment,
    );
  }

  @override
  PaymentEncashmentPageState createState() {
    return PaymentEncashmentPageState(
      appConfiguration: appConfiguration,
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
      paymentEncashmentId: paymentEncashmentId,
    );
  }
}

class PaymentEncashmentPageState extends LoadingSupportState<PaymentEncashmentPage> {
  static const String CANCEL = "cancel";

  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentEncashmentId;
  final String paymentAuthorizationId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<PaymentEncashmentEntity> _paymentEncashmentStream;
  bool loading = false;

  PaymentEncashmentPageState({
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.paymentEncashmentId,
  });

  @override
  void initState() {
    super.initState();
    _paymentEncashmentStream = PaymentEncashmentStore(appConfiguration).subscribeForPaymentEncashment(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
      paymentEncashmentId: paymentEncashmentId,
    );
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
        title: Text(localizations.paymentEncashmentEventTitle + appConfiguration.proxyUniverseSuffix),
        actions: <Widget>[
          PopupMenuButton<ActionMenuItem>(
            onSelected: (action) => _onAction(context, action),
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
            initialData: widget.paymentEncashment,
            stream: _paymentEncashmentStream,
            builder: body,
            emptyWidget: _noPaymentEncashmentFound(context),
          ),
        ),
      ),
    );
  }

  Widget body(
    BuildContext context,
    PaymentEncashmentEntity paymentEncashmentEntity,
  ) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return ListView(
      children: [
        const SizedBox(height: 16.0),
        Icon(paymentEncashmentEntity.icon, size: 64.0),
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
              currency: Currency.currencySymbol(paymentEncashmentEntity.amount.currency),
              value: paymentEncashmentEntity.amount.value,
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
            paymentEncashmentEntity.getStatusAsText(localizations),
            style: themeData.textTheme.title,
          ),
        ),
        if (paymentEncashmentEntity.email != null || paymentEncashmentEntity.phone != null) ...[
          const SizedBox(height: 24.0),
          Center(
            child: Text(
              localizations.payee,
            ),
          ),
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              paymentEncashmentEntity.phone ?? paymentEncashmentEntity.email,
              style: themeData.textTheme.title,
            ),
          ),
        ],
        if (paymentEncashmentEntity.secretEncrypted != null) ...[
          const SizedBox(height: 24.0),
          Center(
            child: Text(
              localizations.secretPin,
            ),
          ),
          const SizedBox(height: 8.0),
          Center(
            child: FutureBuilder(
              future: _secret(paymentEncashmentEntity),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data,
                    style: Theme.of(context).textTheme.title,
                  );
                } else {
                  return Text('******');
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _noPaymentEncashmentFound(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.bug_report, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.paymentEncashmentNotFound,
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

  Future<String> _secret(PaymentEncashmentEntity encashment) {
    final encryptionService = SymmetricKeyEncryptionService();
    return encashment.secret ?? encryptionService.decrypt(key: appConfiguration.passPhrase, cipherText: encashment.secretEncrypted);
  }

  void _onAction(BuildContext context, ActionMenuItem action) {
    if (action.action == CANCEL) {
      _cancelPayment(context);
    } else {
      print("Unknown action $action");
    }
  }

  void _cancelPayment(BuildContext context) async {
    final paymentEncashment = await PaymentEncashmentStore(appConfiguration).fetchPaymentEncashment(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
      paymentEncashmentId: paymentEncashmentId,
    );
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (paymentEncashment == null || !paymentEncashment.isCancelPossible) {
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
