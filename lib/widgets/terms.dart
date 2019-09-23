import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';

class TermsAndConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: new Container(),
        title: Text(localizations.termsAndConditionsPageTitle),
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: "Terms & Conditions\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text:
                      "\nBy downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Yagnyam eCommerce LLP .",
                ),
                TextSpan(
                  text:
                  "\nBy downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Yagnyam eCommerce LLP .",
                ),
                TextSpan(
                  text:
                  "\nBy downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Yagnyam eCommerce LLP .",
                ),
                TextSpan(
                  text:
                  "\nBy downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Yagnyam eCommerce LLP .",
                ),
              ]),
            ),
          ),
          SizedBox(height: 16.0),
          _acceptButton(context),
        ],
      ),
    );
  }

  Widget _acceptButton(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        RaisedButton(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
          shape: StadiumBorder(),
          child: Text(
            localizations.acceptTermsAndConditionsButtonLabel,
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
