import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/proxy_accounts_page.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/db/receiving_account_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class ReceivingAccountDialog extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ReceivingAccountEntity receivingAccount;

  ReceivingAccountDialog(this.appConfiguration, {Key key, this.receivingAccount}) : super(key: key) {
    print("Constructing ReceivingAccountDialog");
    assert(appConfiguration != null);
  }

  @override
  _ReceivingAccountDialogState createState() => _ReceivingAccountDialogState(appConfiguration, receivingAccount);
}

class _ReceivingAccountDialogState extends State<ReceivingAccountDialog> {
  final AppConfiguration appConfiguration;
  final ReceivingAccountStore _receivingAccountStore;
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
  String _currency;

  _ReceivingAccountDialogState(this.appConfiguration, this.receivingAccount)
      : _receivingAccountStore = ReceivingAccountStore(appConfiguration),
        accountNameController = TextEditingController(text: receivingAccount?.accountName),
        accountNumberController = TextEditingController(text: receivingAccount?.accountNumber),
        accountHolderController = TextEditingController(text: receivingAccount?.accountHolder),
        bankController = TextEditingController(text: receivingAccount?.bankName),
        ifscCodeController = TextEditingController(text: receivingAccount?.ifscCode),
        emailController = TextEditingController(text: receivingAccount?.email),
        phoneController = TextEditingController(text: receivingAccount?.phone),
        addressController = TextEditingController(text: receivingAccount?.address) {
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
    String title = receivingAccount?.accountId == null
        ? localizations.newReceivingAccountTitle
        : localizations.modifyReceivingAccountTitle;
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

  void _submit(ProxyLocalizations localizations) async {
    if (_currency == null || _currency.isEmpty) {
      print("Invalid currency");
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (!_formKey.currentState.validate()) {
      print("Validation failure");
    } else {
      ReceivingAccountEntity result = await _receivingAccountStore.saveAccount(
        ReceivingAccountEntity(
          proxyUniverse: appConfiguration.proxyUniverse,
          accountId: receivingAccount?.accountId ?? uuidFactory.v4(),
          currency: _currency,
          accountName: accountNameController.text,
          accountNumber: accountNumberController.text,
          accountHolder: accountHolderController.text,
          bankName: bankController.text,
          ifscCode: ifscCodeController.text,
          email: emailController.text,
          phone: phoneController.text,
          address: addressController.text,
          active: receivingAccount?.active ?? true,
        ),
      );
      Navigator.of(context).pop(result);
    }
  }

  String _fieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
