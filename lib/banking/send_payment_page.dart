import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_reader/flutter_nfc_reader.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/peer_service.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:promo/widgets/peer_finder.dart';
import 'package:proxy_core/services.dart';
import 'package:uri/uri.dart';

class SendPaymentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final PaymentAuthorizationEntity paymentAuthorization;

  SendPaymentPage(
    this.appConfiguration, {
    Key key,
    this.paymentAuthorization,
  }) : super(key: key);

  @override
  SendPaymentPageState createState() {
    return SendPaymentPageState(
      appConfiguration: appConfiguration,
      paymentAuthorization: paymentAuthorization,
    );
  }
}

class SendPaymentPageState extends LoadingSupportState<SendPaymentPage> {
  final AppConfiguration appConfiguration;
  final PaymentAuthorizationEntity paymentAuthorization;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  Future<String> _paymentLinkFuture;

  SendPaymentPageState({
    @required this.appConfiguration,
    @required this.paymentAuthorization,
  });

  @override
  void initState() {
    super.initState();
    _paymentLinkFuture = _paymentLinkWithSecret();
    _sendPaymentAuthorizationByNfc();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.sendPaymentPageTitle + appConfiguration.proxyUniverseSuffix),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: futureBuilder(
              future: _paymentLinkFuture,
              builder: (context, paymentLink) {
                return PeerFinder(
                  appConfiguration: appConfiguration,
                  data: paymentLink,
                  onPeerFound: (p) => _sendPayment(context, p),
                );
              }),
        ),
      ),
    );
  }

  void _sendPayment(BuildContext context, Peer peer) {
    print("Sent payment to $peer");
    Navigator.of(context).pop(true);
  }

  Future<String> _fetchSecret() {
    final encryptionService = SymmetricKeyEncryptionService();
    return encryptionService.decrypt(
      key: appConfiguration.passPhrase,
      cipherText: paymentAuthorization.payees.first.secretEncrypted,
    );
  }

  Future<String> _paymentLinkWithSecret() async {
    String secret = await _fetchSecret();
    final url = paymentAuthorization.paymentAuthorizationLink ?? paymentAuthorization.paymentAuthorizationDynamicLink;
    final paymentLinkBuilder = UriBuilder.fromUri(Uri.parse(url));
    paymentLinkBuilder.fragment = "secret=$secret";
    return paymentLinkBuilder.toString();
  }

  Future<void> _sendPaymentAuthorizationByNfc() async {
    if (Platform.isIOS) {
      print("iOS doesnt support NFC Tag writing");
      return;
    }
    String link = await _paymentLinkWithSecret();
    print("Send Payment $link by NFC");
    try {
      FlutterNfcReader.write("payment", link).then((writeResponse) {
        print('Sent: ${writeResponse.content}');
        showMessage(ProxyLocalizations
            .of(context)
            .paymentSentThroughNfc);
      });
    } catch (e) {
      print("Error sending payment by NFC: $e");
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
}
