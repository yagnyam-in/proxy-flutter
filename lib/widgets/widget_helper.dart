import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';

mixin WidgetHelper {
  Future<String> acceptStringDialog(
    BuildContext context, {
    @required String pageTitle,
    @required String fieldName,
    String fieldInitialValue,
    String buttonLabel,
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
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
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
}
