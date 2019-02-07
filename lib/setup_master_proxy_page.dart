

import 'package:flutter/material.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/proxy_impl.dart';

class SetupMasterProxyPage extends StatefulWidget {

  final AppConfiguration appConfiguration;

  SetupMasterProxyPage({Key key, @required this.appConfiguration}) : super(key: key);

  @override
  _SetupMasterProxyPageState createState() => _SetupMasterProxyPageState();
}

class _SetupMasterProxyPageState extends State<SetupMasterProxyPage> {
  String message = "Click";

  ProxyVersion proxyVersion = ProxyVersion.latestVersion();

  Future<ProxyRequest> createProxyRequest() {
    print("createProxyRequest");
    ProxyRequestFactory proxyRequestFactory = ProxyRequestFactoryImpl();
    return proxyRequestFactory.createProxyRequest(
      id: "hello",
      signatureAlgorithm: proxyVersion.certificateSignatureAlgorithm,
      revocationPassPhrase: "hello",
      keyGenerationAlgorithm: proxyVersion.keyGenerationAlgorithm,
      keySize: proxyVersion.keySize,
    );
  }


  void _incrementCounter() {
    createProxyRequest().then((ProxyRequest r) {
      setState(() {
        message = "Success!! ${r.localAlias}";
      });
    }).catchError((e) {
      setState(() {
        message = "Failure!! $e";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).setupMasterProxyTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$message',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
