import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_messages/banking.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class DepositRequestInput with ProxyUtils {
  final String currency;
  final double amount;
  final String accountName;
  final String message;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  DepositRequestInput._internal({
    @required this.currency,
    this.amount,
    this.accountName,
    this.message,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  factory DepositRequestInput.forAccount(ProxyAccountEntity proxyAccount, [UserEntity user]) {
    return DepositRequestInput._internal(
      currency: proxyAccount.balance.currency,
      accountName: proxyAccount.validAccountName,
      customerName: user?.name,
      customerPhone: user?.phone,
      customerEmail: user?.email,
    );
  }

  factory DepositRequestInput.fromCustomer(UserEntity user) {
    return DepositRequestInput._internal(
      currency: null,
      customerName: user?.name,
      customerPhone: user?.phone,
      customerEmail: user?.email,
    );
  }

  RequestingCustomer get requestingCustomer {
    if (isNotEmpty(customerName) && isNotEmpty(customerPhone) && isNotEmpty(customerEmail)) {
      return RequestingCustomer(name: customerName, phone: customerPhone, email: customerEmail);
    }
    return null;
  }

  void assertValid() {
    assert(currency != null);
    assert(Currency.isValidCurrency(currency));
    assert(isNotEmpty(message));
    if (currency == Currency.INR) {
      assert(isNotEmpty(customerName));
      assert(isNotEmpty(customerPhone));
      assert(isNotEmpty(customerEmail));
    }
  }
}

class DepositRequestInputDialog extends StatefulWidget {
  final DepositRequestInput depositRequestInput;

  DepositRequestInputDialog({Key key, this.depositRequestInput}) : super(key: key) {
    print("Constructing DepositRequestInputDialog with Input $depositRequestInput");
  }

  @override
  _DepositRequestInputDialogState createState() => _DepositRequestInputDialogState(depositRequestInput);
}

class _DepositRequestInputDialogState extends State<DepositRequestInputDialog> {
  final DepositRequestInput depositRequestInput;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> validCurrencies;

  final TextEditingController messageController;
  final TextEditingController amountController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  String _currency;

  _DepositRequestInputDialogState(this.depositRequestInput)
      : amountController = TextEditingController(),
        messageController = TextEditingController(text: depositRequestInput?.message),
        nameController = TextEditingController(text: depositRequestInput?.customerName),
        phoneController = TextEditingController(text: depositRequestInput?.customerPhone),
        emailController = TextEditingController(text: depositRequestInput?.customerEmail),
        _currency = depositRequestInput?.currency,
        validCurrencies =
            depositRequestInput?.currency != null ? [depositRequestInput.currency] : [Currency.INR, Currency.EUR];

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (messageController.text.isEmpty) {
      messageController.text = localizations.depositEventSubTitle(depositRequestInput.accountName);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.depositRequestInputTitle),
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

    List<Widget> children = [];

    children.addAll([
      const SizedBox(height: 16.0),
      new FormField(
        builder: (FormFieldState state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.currency,
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
        controller: amountController,
        decoration: InputDecoration(
          labelText: localizations.amount,
        ),
        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
        validator: (value) => _amountValidator(localizations, value),
      ),
    ]);

    if (_currency == Currency.INR) {
      children.addAll([
        const SizedBox(height: 16.0),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: localizations.customerName,
          ),
          keyboardType: TextInputType.text,
          validator: (value) => _fieldValidator(localizations, value),
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: localizations.customerPhone,
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => _fieldValidator(localizations, value),
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: localizations.customerEmail,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => _fieldValidator(localizations, value),
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
    if (_currency == null) {
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (_formKey.currentState.validate()) {
      DepositRequestInput result = DepositRequestInput._internal(
        currency: _currency,
        amount: double.parse(amountController.text),
        message: messageController.text,
        customerName: nameController.text,
        customerEmail: emailController.text,
        customerPhone: phoneController.text,
      );
      print("Accepting $result");
      Navigator.of(context).pop(result);
    } else {
      print("Validation failure");
    }
  }

  String _amountValidator(ProxyLocalizations localizations, String value) {
    if (value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    } else if (double.tryParse(value) == null || double.parse(value) <= 0) {
      return localizations.invalidAmount;
    }
    return null;
  }

  String _fieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
