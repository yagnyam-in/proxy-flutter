import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class AcceptAmountDialog extends StatefulWidget {
  final String currency;

  AcceptAmountDialog({Key key, this.currency}) : super(key: key) {
    print("Constructing AcceptAmountDialog");
  }

  @override
  _AcceptAmountDialogState createState() => _AcceptAmountDialogState();
}

class _AcceptAmountDialogState extends State<AcceptAmountDialog> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController valueController = TextEditingController();
  final List<String> validCurrencies = [Currency.INR, Currency.EUR];

  String _currency;

  void showError(String message) {
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
        title: Text(localizations.enterAmountTitle),
        actions: [
          new FlatButton(
              onPressed: _submit,
              child: new Text(localizations.okButtonLabel,
                  style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white))),
        ],
      ),
      body: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: form(context),
      ),
    );
  }

  Widget form(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 16.0),
          new FormField(
            builder: (FormFieldState state) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: localizations.currency,
                  // helperText: localizations.currencyHint,
                ),
                isEmpty: _currency == '',
                child: new DropdownButtonHideUnderline(
                  child: new DropdownButton(
                    value: _currency,
                    isDense: true,
                    onChanged: (String newValue) {
                      setState(() {
                        _currency = newValue;
                        state.didChange(newValue);
                      });
                    },
                    items: validCurrencies.map((String value) {
                      return new DropdownMenuItem(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: valueController,
            decoration: InputDecoration(
              labelText: localizations.amount,
              // helperText: localizations.amountHint,
            ),
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
            validator: (value) => _amountValidator(localizations, value),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      print("Accepting amount $_currency ${valueController.text}");
      Navigator.of(context).pop(new Amount(_currency, double.parse(valueController.value.text)));
    } else {
      print("Validation failure");
    }
  }

  String _amountValidator(ProxyLocalizations localizations, String amount) {
    if (amount.isEmpty) {
      return localizations.fieldIsMandatory(localizations.currency);
    } else if (double.tryParse(amount) == null) {
      return localizations.invalidAmount;
    }
    return null;
  }
}
