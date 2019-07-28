import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/banking/widgets/currency_input_form_field.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class PaymentAuthorizationPayeeInput with ProxyUtils {
  final String customerPhone;
  final String customerEmail;
  final String secret;
  final ProxyId payeeProxyId;

  PaymentAuthorizationPayeeInput({
    this.customerPhone,
    this.customerEmail,
    this.secret,
    this.payeeProxyId,
  });

  PayeeTypeEnum get payeeType {
    if (payeeProxyId != null) {
      return PayeeTypeEnum.ProxyId;
    } else if (isNotEmpty(customerEmail)) {
      return PayeeTypeEnum.Email;
    } else if (isNotEmpty(customerPhone)) {
      return PayeeTypeEnum.Phone;
    }
    return PayeeTypeEnum.AnyoneWithSecret;
  }

  void assertValid() {
    switch (payeeType) {
      case PayeeTypeEnum.ProxyId:
        payeeProxyId.assertValid();
        break;
      case PayeeTypeEnum.Email:
        assert(isNotEmpty(customerEmail));
        assert(isNotEmpty(secret));
        break;
      case PayeeTypeEnum.Phone:
        assert(isNotEmpty(customerPhone));
        assert(isNotEmpty(secret));
        break;
      case PayeeTypeEnum.AnyoneWithSecret:
        assert(isNotEmpty(secret));
        break;
    }
  }
}

class PaymentAuthorizationInput with ProxyUtils {
  final String currency;
  final double amount;
  final String message;
  final List<PaymentAuthorizationPayeeInput> payees;

  PaymentAuthorizationInput({
    this.currency,
    this.amount,
    this.message,
    this.payees,
  });

  void assertValid() {
    assert(currency != null);
    assert(Currency.isValidCurrency(currency));
    assert(isNotEmpty(message));
    assert(payees != null);
    assert(payees.isNotEmpty);
    payees.forEach((p) => p.assertValid());
  }
}

class PaymentAuthorizationInputDialog extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final PaymentAuthorizationInput paymentAuthorizationInput;

  PaymentAuthorizationInputDialog(this.appConfiguration, {Key key, this.paymentAuthorizationInput}) : super(key: key) {
    print("Constructing PaymentAuthorizationInputDialog(proxyUniverse: ${appConfiguration.proxyUniverse}) with Input:$paymentAuthorizationInput");
  }

  @override
  _PaymentAuthorizationInputDialogState createState() =>
      _PaymentAuthorizationInputDialogState(appConfiguration, paymentAuthorizationInput);
}

class _PaymentAuthorizationInputDialogState extends State<PaymentAuthorizationInputDialog> with ProxyUtils {
  final AppConfiguration appConfiguration;
  final PaymentAuthorizationInput paymentAuthorizationInput;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Future<Set<String>> _validCurrenciesFuture;

  final TextEditingController messageController;
  final TextEditingController amountController;
  final TextEditingController secretController;

  FocusNode _amountFocusNode;
  FocusNode _messageFocusNode;
  FocusNode _submitFocusNode;

  String _currency;

  _PaymentAuthorizationInputDialogState(this.appConfiguration, this.paymentAuthorizationInput)
      : amountController = TextEditingController(),
        messageController = TextEditingController(text: paymentAuthorizationInput?.message),
        secretController = TextEditingController(text: paymentAuthorizationInput?.payees?.first?.secret),
        _currency = paymentAuthorizationInput?.currency;

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode();
    _messageFocusNode = FocusNode();
    _submitFocusNode = FocusNode();
    if (isNotEmpty(_currency)) {
      _validCurrenciesFuture =  Future.value({_currency});
    } else {
      _validCurrenciesFuture =  BankingServiceFactory.bankingService(appConfiguration).supportedCurrenciesForDefaultBank();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _amountFocusNode.dispose();
    _messageFocusNode.dispose();
    _submitFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.paymentAuthorizationInputTitle),
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
      CurrencyInputFormField.forCurrencies(
        preferredCurrency: appConfiguration.account.preferredCurrency,
        validCurrenciesFuture: _validCurrenciesFuture,
        onChanged: (String newValue) {
          _currency = newValue;
          if (_currency != null) {
            FocusScope.of(context).requestFocus(_amountFocusNode);
          }
        },
      ),
      const SizedBox(height: 16.0),
      TextFormField(
        focusNode: _amountFocusNode,
        controller: amountController,
        decoration: InputDecoration(
          labelText: localizations.amount,
        ),
        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
        validator: (value) => _amountValidator(localizations, value),
        onFieldSubmitted: (val) => FocusScope.of(context).requestFocus(_messageFocusNode),
        textInputAction: TextInputAction.next,
      ),
    ]);

    children.addAll([
      const SizedBox(height: 16.0),
      TextFormField(
        focusNode: _messageFocusNode,
        controller: messageController,
        decoration: InputDecoration(
          labelText: localizations.message,
        ),
        keyboardType: TextInputType.text,
        validator: (value) => _mandatoryFieldValidator(localizations, value),
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (val) => FocusScope.of(context).requestFocus(_submitFocusNode),
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

    children.addAll([
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        alignment: Alignment.center,
        child: RaisedButton(
          focusNode: _submitFocusNode,
          onPressed: () => _submit(localizations),
          child: Text(localizations.createAndShareButtonLabel),
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
    if (_currency == null) {
      showError(localizations.fieldIsMandatory(localizations.currency));
    } else if (_formKey.currentState.validate()) {
      AccountService.fromAppConfig(appConfiguration).updatePreferences(
        appConfiguration.account,
        currency: _currency,
      );
      PaymentAuthorizationInput result = PaymentAuthorizationInput(
        currency: _currency,
        amount: double.parse(amountController.text),
        message: messageController.text,
        payees: [
          PaymentAuthorizationPayeeInput(
            secret: secretController.text,
          ),
        ],
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
