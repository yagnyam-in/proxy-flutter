import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_reader/flutter_nfc_reader.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/peer_service.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:promo/widgets/peer_finder.dart';

class ReceivePaymentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  ReceivePaymentPage(
    this.appConfiguration, {
    Key key,
  }) : super(key: key);

  @override
  ReceivePaymentPageState createState() {
    return ReceivePaymentPageState(
      appConfiguration: appConfiguration,
    );
  }
}

class ReceivePaymentPageState extends LoadingSupportState<ReceivePaymentPage> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool loading = false;

  ReceivePaymentPageState({
    @required this.appConfiguration,
  });

  @override
  void initState() {
    super.initState();
    _readFromNfc();
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
        title: Text(localizations.receivePaymentPageTitle + appConfiguration.proxyUniverseSuffix),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: PeerFinder(
            appConfiguration: appConfiguration,
            onPeerFound: (p) => _receivePayment(context, p),
          ),
        ),
      ),
    );
  }

  void _receivePayment(BuildContext context, Peer peer) {
    print("Receiving payment from $peer - ${peer.data}");
    Uri paymentLink = Uri.parse(peer.data);
    Navigator.of(context).pop(paymentLink);
  }

  void showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _readFromNfc() {
    if (Platform.isIOS) {
      print("iOS doesnt support NFC Tag reading");
      return;
    }
    try {
      FlutterNfcReader.onTagDiscovered().listen((onData) {
        print("onTag: ${onData.id}");
        print("onTag: ${onData.content}");
        if (onData.content != null) {
          Uri paymentLink = Uri.parse(onData.content);
          Navigator.of(context).pop(paymentLink);
        }
      });
    } catch (e) {
      print("Error listening for NFC tags: $e");
    }
  }
}
