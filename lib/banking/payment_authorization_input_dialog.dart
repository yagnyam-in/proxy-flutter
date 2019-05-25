import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class PaymentAuthorizationInput with ProxyUtils {
  final String proxyUniverse;
  final String currency;
  final double amount;
  final String message;
  final String customerPhone;
  final String customerEmail;
  final String secret;
  final ProxyId payeeProxyId;

  PaymentAuthorizationInput({
    this.proxyUniverse,
    this.currency,
    this.amount,
    this.message,
    this.customerPhone,
    this.customerEmail,
    this.secret,
    this.payeeProxyId,
  });

  void assertValid() {
    assert(isNotEmpty(proxyUniverse));
    assert(currency != null);
    assert(Currency.isValidCurrency(currency));
    assert(isNotEmpty(message));
  }

  PayeeTypeEnum get payeeType {
    if (payeeProxyId != null) {
      return PayeeTypeEnum.ProxyId;
    } else if (customerEmail != null) {
      return PayeeTypeEnum.Email;
    } else if (customerPhone != null) {
      return PayeeTypeEnum.Phone;
    }
    return PayeeTypeEnum.AnyoneWithSecret;
  }
}

class PaymentAuthorizationInputDialog extends StatefulWidget {
  final PaymentAuthorizationInput paymentAuthorizationInput;

  PaymentAuthorizationInputDialog({Key key, this.paymentAuthorizationInput}) : super(key: key) {
    print("Constructing PaymentAuthorizationInputDialog with Input $paymentAuthorizationInput");
  }

  @override
  _PaymentAuthorizationInputDialogState createState() =>
      _PaymentAuthorizationInputDialogState(paymentAuthorizationInput);
}

class _PaymentAuthorizationInputDialogState extends State<PaymentAuthorizationInputDialog> with ProxyUtils {
  final PaymentAuthorizationInput paymentAuthorizationInput;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController messageController;
  final TextEditingController amountController;
  final TextEditingController secretController;

  String _proxyUniverse;
  String _currency;

  List<String> get validProxyUniverses {
    if (isNotEmpty(paymentAuthorizationInput?.proxyUniverse)) {
      return [paymentAuthorizationInput.proxyUniverse];
    }
    return [ProxyUniverse.PRODUCTION, ProxyUniverse.TEST];
  }

  List<String> get validCurrencies {
    if (isNotEmpty(paymentAuthorizationInput?.currency)) {
      return [paymentAuthorizationInput.currency];
    }
    return [Currency.INR, Currency.EUR];
  }

  _PaymentAuthorizationInputDialogState(this.paymentAuthorizationInput)
      : amountController = TextEditingController(),
        messageController = TextEditingController(text: paymentAuthorizationInput?.message),
        secretController = TextEditingController(text: paymentAuthorizationInput?.secret),
        _currency = paymentAuthorizationInput?.currency,
        _proxyUniverse = paymentAuthorizationInput?.proxyUniverse;

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
        title: Text(localizations.paymentAuthorizationInputTitle),
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

    if (paymentAuthorizationInput?.proxyUniverse != ProxyUniverse.PRODUCTION) {
      children.addAll([
        const SizedBox(height: 16.0),
        new FormField(
          builder: (FormFieldState state) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: localizations.proxyUniverse,
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
      ]);
    }

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


    children.addAll([
      const SizedBox(height: 16.0),
      TextFormField(
        controller: messageController,
        decoration: InputDecoration(
          labelText: localizations.message,
        ),
        keyboardType: TextInputType.text,
      ),
    ]);

    children.addAll([
      const SizedBox(height: 16.0),
      AbsorbPointer(
        absorbing: true,
        child: TextFormField(
          controller: secretController,
          decoration: InputDecoration(
            labelText: localizations.secret,
          ),
          keyboardType: TextInputType.text,
        ),
      ),
    ]);

    return Form(
      key: _formKey,
      child: ListView(
        children: children,
      ),
    );
  }

  void _submit(ProxyLocalizations localizations) {
    if (_proxyUniverse == null) {
      showError(localizations.fieldIsMandatory(localizations.proxyUniverse));
    } else if (_currency == null) {
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (_formKey.currentState.validate()) {
      PaymentAuthorizationInput result = PaymentAuthorizationInput(
        proxyUniverse: _proxyUniverse,
        currency: _currency,
        amount: double.parse(amountController.text),
        message: messageController.text,
        secret: secretController.text,
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

  String _mandatoryFieldValidator(ProxyLocalizations localizations, String value) {
    if (value == null || value.isEmpty) {
      return localizations.fieldIsMandatory(localizations.thisField);
    }
    return null;
  }
}
