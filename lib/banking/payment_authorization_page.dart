import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_store.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/action_menu_item.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:share/share.dart';

class PaymentAuthorizationPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final PaymentAuthorizationEntity paymentAuthorization;

  const PaymentAuthorizationPage(this.appConfiguration, {
    Key key,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    this.paymentAuthorization,
  }) : super(key: key);

  factory PaymentAuthorizationPage.forPaymentAuthorization(AppConfiguration appConfiguration,
      PaymentAuthorizationEntity paymentAuthorization,
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
      ActionMenuItem(title: localizations.sharePaymentTooltip, icon: Icons.share, action: SHARE),
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

  Widget body(BuildContext context,
      PaymentAuthorizationEntity paymentAuthorizationEntity,) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return ListView(
      children: [
        const SizedBox(height: 16.0),
        Icon(paymentAuthorizationEntity.icon, size: 64.0),
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
              currency: Currency.currencySymbol(paymentAuthorizationEntity.amount.currency),
              value: paymentAuthorizationEntity.amount.value,
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
            paymentAuthorizationEntity.getStatusAsText(localizations),
            style: themeData.textTheme.title,
          ),
        ),
        const SizedBox(height: 24.0),
        if (paymentAuthorizationEntity.payees.length == 1)
          ..._singlePayee(context, paymentAuthorizationEntity.payees.first)
        else
          ..._multiplePayees(context, paymentAuthorizationEntity.payees)
      ],
    );
  }

  List<Widget> _singlePayee(BuildContext context, PaymentAuthorizationPayeeEntity payee) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final secret = _secret(payee);
    return [
      Center(
        child: Text(
          localizations.secret,
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
                  style: Theme
                      .of(context)
                      .textTheme
                      .title,
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
          .expand((payee) =>
      <Widget>[
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
    showMessage(ProxyLocalizations
        .of(context)
        .copiedToClipboard);
  }

  String _payeeDisplayName(ProxyLocalizations localizations, PaymentAuthorizationPayeeEntity payee) {
    switch (payee.payeeType) {
      case PayeeTypeEnum.ProxyId:
        return "${payee.proxyId.id.substring(0, 6)}...";
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
    if (action.action == SHARE) {
      _sharePayment(context);
    } else if (action.action == CANCEL) {
      _cancelPayment(context);
    } else {
      print("Unknown action $action");
    }
  }

  void _sharePayment(BuildContext context) async {
    final paymentAuthorization = await PaymentAuthorizationStore(appConfiguration).fetchPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    print("Share Payment ${paymentAuthorization.paymentAuthorizationLink}");
    await Share.share(paymentAuthorization.paymentAuthorizationLink);
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
