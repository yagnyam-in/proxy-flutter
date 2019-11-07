import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/banking/db/payment_authorization_store.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/banking/model/payment_authorization_payee_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/action_menu_item.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:quiver/strings.dart';
import 'package:share/share.dart';

class PaymentAuthorizationPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final PaymentAuthorizationEntity paymentAuthorization;

  const PaymentAuthorizationPage(
    this.appConfiguration, {
    Key key,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    this.paymentAuthorization,
  }) : super(key: key);

  factory PaymentAuthorizationPage.forPaymentAuthorization(
      AppConfiguration appConfiguration, PaymentAuthorizationEntity paymentAuthorization,
      {Key key}) {
    return PaymentAuthorizationPage(
      appConfiguration,
      key: key,
      proxyUniverse: paymentAuthorization.proxyUniverse,
      paymentAuthorizationId: paymentAuthorization.paymentAuthorizationId,
      paymentAuthorization: paymentAuthorization,
    );
  }

  @override
  PaymentAuthorizationPageState createState() {
    return PaymentAuthorizationPageState(
      appConfiguration: appConfiguration,
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
  }
}

class PaymentAuthorizationPageState extends LoadingSupportState<PaymentAuthorizationPage> {
  static const String CANCEL = "cancel";
  static const String SHARE = "share";

  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<PaymentAuthorizationEntity> _paymentAuthorizationStream;
  bool loading = false;

  PaymentAuthorizationPageState({
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
  });

  @override
  void initState() {
    super.initState();
    _paymentAuthorizationStream = PaymentAuthorizationStore(appConfiguration).subscribeForPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
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
        title: Text(localizations.paymentAuthorizationEventTitle + appConfiguration.proxyUniverseSuffix),
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
            initialData: widget.paymentAuthorization,
            stream: _paymentAuthorizationStream,
            builder: body,
            emptyWidget: _noPaymentAuthorizationFound(context),
          ),
        ),
      ),
    );
  }

  Widget body(BuildContext context, PaymentAuthorizationEntity paymentAuthorization) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    final rows = [
      const SizedBox(height: 16.0),
      Icon(paymentAuthorization.icon, size: 64.0),
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
            currency: Currency.currencySymbol(paymentAuthorization.amount.currency),
            value: paymentAuthorization.amount.value,
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
          paymentAuthorization.getStatusAsText(localizations),
          style: themeData.textTheme.title,
        ),
      ),
      const SizedBox(height: 24.0),
      if (paymentAuthorization.payees.length == 1000)
        ..._singlePayee(context, paymentAuthorization.payees.first)
      else
        ..._multiplePayees(context, paymentAuthorization.payees)
    ];

    List<Widget> actions = [];
    if (!paymentAuthorization.completed) {
      actions.add(
        RaisedButton.icon(
          onPressed: () => _sharePaymentAuthorization(context, paymentAuthorization),
          icon: Icon(Icons.share),
          label: Text(localizations.sharePaymentButtonTitle),
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

  List<Widget> _singlePayee(BuildContext context, PaymentAuthorizationPayeeEntity payee) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final secret = _secret(payee);
    return [
      Center(
        child: Text(
          localizations.secretPin,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: FutureBuilder(
          future: secret,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                child: Text(
                  snapshot.data,
                  style: Theme.of(context).textTheme.title,
                ),
                onLongPress: () => _copyToClipboard(context, snapshot.data),
              );
            } else {
              return Text('******');
            }
          },
        ),
      ),
    ];
  }

  List<Widget> _multiplePayees(BuildContext context, List<PaymentAuthorizationPayeeEntity> payees) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      Center(
        child: Text(
          localizations.payees,
        ),
      ),
      const SizedBox(height: 8.0),
      ...payees
          .expand((payee) => <Widget>[
                Divider(),
                _payeeWidget(localizations, payee),
              ])
          .toList()
    ];
  }

  Widget _payeeWidget(ProxyLocalizations localizations, PaymentAuthorizationPayeeEntity payee) {
    final secret = _secret(payee);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(_payeeDisplayName(localizations, payee)),
        FutureBuilder(
          future: secret,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                child: Text(snapshot.data),
                onLongPress: () => _copyToClipboard(context, snapshot.data),
              );
            } else {
              return Text('******');
            }
          },
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String message) {
    Clipboard.setData(new ClipboardData(text: message));
    showMessage(ProxyLocalizations.of(context).copiedToClipboard);
  }

  String _payeeDisplayName(ProxyLocalizations localizations, PaymentAuthorizationPayeeEntity payee) {
    if (isNotEmpty(payee.name)) {
      return payee.name;
    }
    switch (payee.payeeType) {
      case PayeeTypeEnum.ProxyId:
        return "${payee.proxyId.id.substring(0, 13)}...";
      case PayeeTypeEnum.Email:
        return payee.email;
      case PayeeTypeEnum.Phone:
        return payee.phone;
      case PayeeTypeEnum.AnyoneWithSecret:
        return localizations.anyoneWithSecret;
      default:
        return localizations.anyoneWithSecret;
    }
  }

  Widget _noPaymentAuthorizationFound(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.bug_report, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.paymentAuthorizationNotFound,
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

  Future<String> _secret(PaymentAuthorizationPayeeEntity payee) {
    final encryptionService = SymmetricKeyEncryptionService();
    return encryptionService.decrypt(key: appConfiguration.passPhrase, cipherText: payee.secretEncrypted);
  }

  void _onAction(BuildContext context, ActionMenuItem action) {
    if (action.action == CANCEL) {
      _cancelPayment(context);
    } else {
      print("Unknown action $action");
    }
  }

  Future<void> _sharePaymentAuthorization(
    BuildContext context,
    PaymentAuthorizationEntity paymentAuthorization,
  ) async {
    if (paymentAuthorization != null) {
      print("Share Payment ${paymentAuthorization.paymentAuthorizationLink}");
      String customerName = appConfiguration.displayName;
      var from = isNotEmpty(customerName) ? ' - $customerName' : '';
      var message = ProxyLocalizations.of(context).acceptPayment(paymentAuthorization.paymentAuthorizationLink + from);
      await Share.share(message);
    }
  }

  void _cancelPayment(BuildContext context) async {
    final paymentAuthorization = await PaymentAuthorizationStore(appConfiguration).fetchPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (paymentAuthorization == null || !paymentAuthorization.isCancelPossible) {
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
