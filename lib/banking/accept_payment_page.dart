import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

class AcceptPaymentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;
  final String paymentAuthorizationId;

  const AcceptPaymentPage({
    @required this.appConfiguration,
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
          child: FutureBuilder<SignedMessage<PaymentAuthorization>>(
            future: _paymentAuthorization,
            builder: (BuildContext context, AsyncSnapshot<SignedMessage<PaymentAuthorization>> snapshot) {
              return body(context, localizations, snapshot);
            },
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

  Widget body(BuildContext context, ProxyLocalizations localizations,
      AsyncSnapshot<SignedMessage<PaymentAuthorization>> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      if (snapshot.hasError) {
        return new Text(
          '${snapshot.error}',
          style: TextStyle(color: Colors.red),
        );
      } else if (snapshot.data == null) {
        return new Text(
          localizations.invalidPayment,
          style: TextStyle(color: Colors.red),
        );
      } else {
        return _AcceptPaymentPageBody(
          appConfiguration: appConfiguration,
          paymentAuthorization: snapshot.data,
        );
      }
    }
    print("Status: ${snapshot.connectionState}");
    return new Center(child: new CircularProgressIndicator());
  }
}

class _AcceptPaymentPageBody extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;

  const _AcceptPaymentPageBody({
    Key key,
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

class _AcceptPaymentPageBodyState extends State<_AcceptPaymentPageBody> {
  final AppConfiguration appConfiguration;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;
  final TextEditingController secretController;
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
    return FutureBuilder<bool>(
      future: _paymentCanBeAcceptedFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _builder(context, snapshot.data);
        } else {
          return new Center(child: new CircularProgressIndicator());
        }
      },
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
        ...paymentCanBeAccepted
            ? [
                const SizedBox(height: 24.0),
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
                ButtonBar(
                  alignment: MainAxisAlignment.spaceAround,
                  children: [
                    RaisedButton.icon(
                      onPressed: () => acceptPayment(context),
                      icon: Icon(Icons.file_download),
                      label: Text(localizations.acceptPaymentButtonLabel),
                    )
                  ],
                ),
              ]
            : [
                const SizedBox(height: 24.0),
                Center(
                  child: Text(
                    localizations.paymentCanNotBeAccepted,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 8.0),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceAround,
                  children: [
                    RaisedButton.icon(
                      onPressed: close,
                      icon: Icon(Icons.close),
                      label: Text(localizations.closeButtonLabel),
                    )
                  ],
                ),
              ]
      ],
    );
  }

  Future<bool> _canPaymentBeAccepted() async {
    for (var payee in paymentAuthorization.message.payees) {
      if (payee.payeeType == PayeeTypeEnum.ProxyId) {
        return await ServiceFactory.proxyKeyRepo().hashProxyKey(payee.proxyId);
      }
    }
    return true;
  }

  Future<void> acceptPayment(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    Payee payee = await BankingServiceFactory.paymentAuthorizationService(appConfiguration).matchingPayee(
      paymentAuthorization: paymentAuthorization.message,
      secret: secretController.text,
    );
    if (payee == null) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(localizations.invalidSecret),
        duration: Duration(seconds: 3),
      ));
    }
    return null;
  }

  void close() {
    Navigator.of(context).pop();
  }
}
