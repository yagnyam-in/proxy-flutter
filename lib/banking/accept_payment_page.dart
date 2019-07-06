import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

class AcceptPaymentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;

  const AcceptPaymentPage(
    this.appConfiguration, {
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    Key key,
  }) : super(key: key);

  @override
  AcceptPaymentPageState createState() {
    return AcceptPaymentPageState(
      appConfiguration: appConfiguration,
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
  }
}

class AcceptPaymentPageState extends LoadingSupportState<AcceptPaymentPage> with ProxyUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  Future<SignedMessage<PaymentAuthorization>> _paymentAuthorization;
  bool loading = false;

  AcceptPaymentPageState({
    @required this.appConfiguration,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
  });

  @override
  void initState() {
    super.initState();
    _paymentAuthorization = _fetchPaymentAuthorization();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.acceptPaymentPageTitle),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: futureBuilder(
            name: "Payment Authorization Fetcher",
            future: _paymentAuthorization,
            emptyMessage: localizations.invalidPayment,
            builder: (context, authorization) => _AcceptPaymentPageBody(
              scaffoldKey: _scaffoldKey,
              appConfiguration: appConfiguration,
              paymentAuthorization: authorization,
            ),
          ),
        ),
      ),
    );
  }

  Future<SignedMessage<PaymentAuthorization>> _fetchPaymentAuthorization() {
    return BankingServiceFactory.paymentAuthorizationService(appConfiguration).fetchPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
  }
}

class _AcceptPaymentPageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;

  const _AcceptPaymentPageBody({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.paymentAuthorization,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AcceptPaymentPageBodyState(
      appConfiguration: appConfiguration,
      paymentAuthorization: paymentAuthorization,
    );
  }
}

class _AcceptPaymentPageBodyState extends LoadingSupportState<_AcceptPaymentPageBody> {
  final AppConfiguration appConfiguration;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;
  final TextEditingController secretController;
  bool loading = false;
  Future<bool> _paymentCanBeAcceptedFuture;

  _AcceptPaymentPageBodyState({Key key, @required this.appConfiguration, @required this.paymentAuthorization})
      : secretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentCanBeAcceptedFuture = _canPaymentBeAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return futureBuilder(
      future: _paymentCanBeAcceptedFuture,
      builder: _builder,
    );
  }

  Widget _builder(BuildContext context, bool paymentCanBeAccepted) {
    var amount = paymentAuthorization.message.amount;

    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.file_download, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.amount,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Text(
            '${amount.value} ${Currency.currencySymbol(amount.currency)}',
            style: themeData.textTheme.title,
          ),
        ),
        if (paymentCanBeAccepted) ..._acceptPayment(context) else ..._paymentCanNotBeAccepted(context)
      ],
    );
  }

  List<Widget> _acceptPayment(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      if (_hasPaymentBySecret()) ...[
        Center(
          child: Text(
            localizations.enterSecretCode,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: TextField(
              controller: secretController,
              maxLines: 1,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
      ],
      ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: [
          RaisedButton.icon(
            onPressed: () => invoke(
              () => acceptPayment(context),
              name: 'Accept Payment',
              onError: () => showMessage(localizations.somethingWentWrong),
            ),
            icon: Icon(Icons.file_download),
            label: Text(localizations.acceptPaymentButtonLabel),
          )
        ],
      ),
    ];
  }

  List<Widget> _paymentCanNotBeAccepted(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.paymentCanNotBeAccepted,
          style: TextStyle(color: Colors.red),
        ),
      ),
    ];
  }

  Future<bool> _canPaymentBeAccepted() async {
    if (_hasPaymentBySecret()) {
      return true;
    }
    return _isPaymentByPayeeId();
  }

  Future<bool> _isPaymentByPayeeId() async {
    List<bool> payees = await Future.wait(paymentAuthorization.message.payees.map((payee) async {
      if (payee.payeeType == PayeeTypeEnum.ProxyId) {
        return ProxyKeyStore(appConfiguration).hasProxyKey(payee.proxyId);
      }
      return false;
    }).toList());
    return payees.any((x) => x);
  }

  bool _hasPaymentBySecret() {
    for (var payee in paymentAuthorization.message.payees) {
      if (payee.payeeType != PayeeTypeEnum.ProxyId) {
        return true;
      }
    }
    return false;
  }

  Future<void> acceptPayment(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final paymentAuthorizationService = BankingServiceFactory.paymentAuthorizationService(appConfiguration);
    Payee payee = await paymentAuthorizationService.matchingPayee(
      paymentAuthorization: paymentAuthorization.message,
      secret: secretController.text,
    );
    if (payee == null) {
      showMessage(localizations.invalidSecret);
      return null;
    }
    await paymentAuthorizationService.acceptPayment(
      paymentAuthorization: paymentAuthorization,
      payee: payee,
    );
    return null;
  }

  void showMessage(String message) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void close() {
    Navigator.of(context).pop();
  }
}
