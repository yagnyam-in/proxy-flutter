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
  _ReceivingAccountDialogState createState() => _ReceivingAccountDialogState(receivingAccount);
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
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  final List<String> validCurrencies = [Currency.INR, Currency.EUR];
  final List<String> validProxyUniverses = [ProxyUniverse.PRODUCTION, ProxyUniverse.TEST];

  String _proxyUniverse;
  String _currency;

  _ReceivingAccountDialogState(this.receivingAccount)
      : accountNameController = TextEditingController(text: receivingAccount?.accountName),
        accountNumberController = TextEditingController(text: receivingAccount?.accountNumber),
        accountHolderController = TextEditingController(text: receivingAccount?.accountHolder),
        bankController = TextEditingController(text: receivingAccount?.bank),
        ifscCodeController = TextEditingController(text: receivingAccount?.ifscCode),
        emailController = TextEditingController(text: receivingAccount?.email),
        phoneController = TextEditingController(text: receivingAccount?.phone),
        addressController = TextEditingController(text: receivingAccount?.address) {
    _proxyUniverse = receivingAccount?.proxyUniverse;
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
    String title =
        receivingAccount == null ? localizations.newReceivingAccountTitle : localizations.modifyReceivingAccountTitle;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: [
          new FlatButton(
              onPressed: () => _submit(localizations),
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

    List<Widget> children = [
      new FormField(
        builder: (FormFieldState state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.proxyUniverse,
              // helperText: localizations.currencyHint,
            ),
            isEmpty: _proxyUniverse == '',
            child: new DropdownButtonHideUnderline(
              child: new DropdownButton(
                value: _proxyUniverse,
                isDense: true,
                onChanged: (String newValue) {
                  setState(() {
                    _proxyUniverse = newValue;
                    state.didChange(newValue);
                  });
                },
                items: validProxyUniverses.map((String value) {
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
      new TextFormField(
        controller: accountNumberController,
        decoration: InputDecoration(
          labelText: localizations.accountNumber,
        ),
        validator: (value) => _fieldValidator(localizations, value),
      ),
      const SizedBox(height: 8.0),
      new TextFormField(
        controller: accountHolderController,
        decoration: InputDecoration(
          labelText: localizations.accountHolder,
        ),
        validator: (value) => _fieldValidator(localizations, value),
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
    ];

    if (_currency == Currency.INR) {
      children.addAll([
        const SizedBox(height: 8.0),
        new TextFormField(
          controller: ifscCodeController,
          decoration: InputDecoration(
            labelText: localizations.ifscCode,
          ),
          validator: (value) => _currency == Currency.INR ? _fieldValidator(localizations, value) : null,
        ),
        const SizedBox(height: 8.0),
        new TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: localizations.customerEmail,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _currency == Currency.INR ? _fieldValidator(localizations, value) : null,
        ),
        const SizedBox(height: 8.0),
        new TextFormField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: localizations.customerPhone,
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => _currency == Currency.INR ? _fieldValidator(localizations, value) : null,
        ),
        const SizedBox(height: 8.0),
        new TextFormField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: localizations.customerAddress,
          ),
          keyboardType: TextInputType.text,
          validator: (value) => _currency == Currency.INR ? _fieldValidator(localizations, value) : null,
        ),
      ]);
    }

    return Form(
      key: _formKey,
      child: ListView(
        children: children,
      ),
    );
  }

  void _submit(ProxyLocalizations localizations) {
    if (_proxyUniverse == null || _proxyUniverse.isEmpty) {
      print("Invalid Proxy Universe");
      showError(localizations.fieldIsMandatory(localizations.proxyUniverse));
    } else if (_currency == null || _currency.isEmpty) {
      print("Invalid currency");
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (!_formKey.currentState.validate()) {
      print("Validation failure");
    } else {
      Navigator.of(context).pop(new ReceivingAccountEntity(
        proxyUniverse: _proxyUniverse,
        id: receivingAccount?.id,
        accountName: accountNameController.text,
        accountNumber: accountNumberController.text,
        accountHolder: accountHolderController.text,
        bank: bankController.text,
        currency: _currency,
        ifscCode: ifscCodeController.text,
        email: emailController.text,
        phone: phoneController.text,
        address: addressController.text,
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
