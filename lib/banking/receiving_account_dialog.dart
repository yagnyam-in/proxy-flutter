import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_messages/banking.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class ReceivingAccountDialog extends StatefulWidget {
  final ReceivingAccountEntity receivingAccount;

  ReceivingAccountDialog({Key key, this.receivingAccount}) : super(key: key) {
    print("Constructing ReceivingAccountDialog");
  }

  @override
  _ReceivingAccountDialogState createState() =>
      _ReceivingAccountDialogState(receivingAccount);
}

class _ReceivingAccountDialogState extends State<ReceivingAccountDialog> {
  final ReceivingAccountEntity receivingAccount;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController accountNameController;
  final TextEditingController accountNumberController;
  final TextEditingController accountHolderController;
  final TextEditingController bankController;
  final TextEditingController ifscCodeController;
  final List<String> validCurrencies = [Currency.INR, Currency.EUR];

  String _currency;

  _ReceivingAccountDialogState(this.receivingAccount)
      : accountNameController =
            TextEditingController(text: receivingAccount?.accountName),
        accountNumberController =
            TextEditingController(text: receivingAccount?.accountNumber),
        accountHolderController =
            TextEditingController(text: receivingAccount?.accountHolder),
        bankController = TextEditingController(text: receivingAccount?.bank),
        ifscCodeController =
            TextEditingController(text: receivingAccount?.ifscCode) {
    _currency = receivingAccount?.currency;
  }

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
              onPressed: () => _submit(localizations),
              child: new Text(localizations.okButtonLabel,
                  style: Theme.of(context)
                      .textTheme
                      .subhead
                      .copyWith(color: Colors.white))),
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
          const SizedBox(height: 8.0),
          TextFormField(
            controller: bankController,
            decoration: InputDecoration(
              labelText: localizations.bank,
            ),
            validator: (value) => _fieldValidator(localizations, value),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: accountNumberController,
            decoration: InputDecoration(
              labelText: localizations.accountNumber,
            ),
            validator: (value) => _fieldValidator(localizations, value),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: accountHolderController,
            decoration: InputDecoration(
              labelText: localizations.accountHolder,
            ),
            validator: (value) => _fieldValidator(localizations, value),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: ifscCodeController,
            decoration: InputDecoration(
              labelText: localizations.ifscCode,
            ),
            validator: (value) => _currency == Currency.INR ? _fieldValidator(localizations, value) : null,
          ),
          /*
          const SizedBox(height: 8.0),
          TextFormField(
            controller: accountNameController,
            decoration: InputDecoration(
              labelText: localizations.accountName,
            ),
          ),
          */
        ],
      ),
    );
  }

  void _submit(ProxyLocalizations localizations) {
    if (_currency == null || _currency.isEmpty) {
      print("Invalid currency");
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (!_formKey.currentState.validate()) {
      print("Validation failure");
    } else {
      Navigator.of(context).pop(new ReceivingAccountEntity(
        id: receivingAccount?.id,
        accountName: accountNameController.text,
        accountNumber: accountNumberController.text,
        accountHolder: accountHolderController.text,
        bank: bankController.text,
        currency: _currency,
        ifscCode: ifscCodeController.text,
        active: receivingAccount?.active ?? true,
      ));
    }
  }

  String _fieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
