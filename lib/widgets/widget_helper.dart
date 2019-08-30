import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';

Future<void> inform(
  BuildContext context, {
  @required String pageTitle,
  @required String pageContent,
  String buttonLabel,
  TextInputType keyboardType,
}) async {
  ProxyLocalizations localizations = ProxyLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(pageTitle),
        content: new Text(pageContent),
        actions: <Widget>[
          RaisedButton(
            child: Text(buttonLabel ?? localizations.okButtonLabel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<bool> acceptConfirmation(
  BuildContext context, {
  @required String pageTitle,
  @required String pageContent,
  String buttonLabel,
  TextInputType keyboardType,
}) async {
  ProxyLocalizations localizations = ProxyLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(pageTitle),
        content: new Text(pageContent),
        actions: <Widget>[
          FlatButton(
            child: Text(localizations.cancelButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          RaisedButton(
            child: Text(buttonLabel ?? localizations.yesButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}

Future<String> acceptInputDialog(
  BuildContext context, {
  @required String pageTitle,
  @required String fieldName,
  String fieldInitialValue,
  String buttonLabel,
  TextInputType keyboardType,
}) async {
  ProxyLocalizations localizations = ProxyLocalizations.of(context);
  var valueController = new TextEditingController(text: fieldInitialValue);
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(pageTitle),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                controller: valueController,
                autofocus: true,
                decoration: new InputDecoration(labelText: fieldName),
                keyboardType: keyboardType,
              ),
            )
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text(localizations.cancelButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(null);
            },
          ),
          RaisedButton(
            child: Text(buttonLabel ?? localizations.okButtonLabel),
            onPressed: () {
              Navigator.of(context).pop(valueController.text);
            },
          ),
        ],
      );
    },
  );
}

Future<String> acceptPhoneNumberDialog(
  BuildContext context, {
  @required String pageTitle,
  @required String fieldName,
  String fieldInitialValue,
  String buttonLabel,
}) async {
  return acceptInputDialog(
    context,
    pageTitle: pageTitle,
    fieldName: fieldName,
    fieldInitialValue: fieldInitialValue,
    buttonLabel: buttonLabel,
    keyboardType: TextInputType.phone,
  );
}

Future<String> acceptEmailDialog(
  BuildContext context, {
  @required String pageTitle,
  @required String fieldName,
  String fieldInitialValue,
  String buttonLabel,
}) async {
  return acceptInputDialog(
    context,
    pageTitle: pageTitle,
    fieldName: fieldName,
    fieldInitialValue: fieldInitialValue,
    buttonLabel: buttonLabel,
    keyboardType: TextInputType.emailAddress,
  );
}

Future<String> acceptNameDialog(
  BuildContext context, {
  @required String pageTitle,
  @required String fieldName,
  String fieldInitialValue,
  String buttonLabel,
}) async {
  return acceptInputDialog(
    context,
    pageTitle: pageTitle,
    fieldName: fieldName,
    fieldInitialValue: fieldInitialValue,
    buttonLabel: buttonLabel,
    keyboardType: TextInputType.text,
  );
}
