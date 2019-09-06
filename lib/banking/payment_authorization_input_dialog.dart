import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/banking/widgets/currency_input_form_field.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/contacts_page.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_messages/payments.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

enum PayeeSelectionMode { ANY_ONE_WITH_SECRET, CHOOSE_FROM_CONTACTS }

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
    } else if (isNotEmpty(customerPhone)) {
      return PayeeTypeEnum.Phone;
    } else if (isNotEmpty(customerEmail)) {
      return PayeeTypeEnum.Email;
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
    this.payees = const [],
  });
}

class PaymentAuthorizationInputDialog extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final PaymentAuthorizationInput paymentAuthorizationInput;

  PaymentAuthorizationInputDialog(this.appConfiguration, {Key key, this.paymentAuthorizationInput}) : super(key: key) {
    print(
        "Constructing PaymentAuthorizationInputDialog(proxyUniverse: ${appConfiguration.proxyUniverse}) with Input:$paymentAuthorizationInput");
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

  final TextEditingController _messageController;
  final TextEditingController _amountController;
  final TextEditingController _secretController;
  final TextEditingController _payeeController;
  Set<ContactEntity> _payees = {};

  FocusNode _amountFocusNode;
  FocusNode _messageFocusNode;
  FocusNode _submitFocusNode;

  String _currency;
  PayeeSelectionMode _payeeSelectionMode = PayeeSelectionMode.ANY_ONE_WITH_SECRET;

  _PaymentAuthorizationInputDialogState(this.appConfiguration, this.paymentAuthorizationInput)
      : _amountController = TextEditingController(),
        _messageController = TextEditingController(text: paymentAuthorizationInput?.message),
        _secretController = TextEditingController(text: RandomUtils.randomSecret()),
        _payeeController = TextEditingController(),
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
      _validCurrenciesFuture = Future.value({_currency});
    } else {
      _validCurrenciesFuture =
          BankingServiceFactory.bankingService(appConfiguration).supportedCurrenciesForDefaultBank();
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
    _payeeController.text = _payeesAsString();
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
        controller: _amountController,
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
        controller: _messageController,
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
      FormField(
        builder: (FormFieldState state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: localizations.sendPaymentToLabel,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PayeeSelectionMode>(
                value: _payeeSelectionMode,
                isDense: true,
                onChanged: (value) {
                  setState(() {
                    _payeeSelectionMode = value;
                  });
                  if (value == PayeeSelectionMode.CHOOSE_FROM_CONTACTS) {
                    _choosePayees(context);
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: PayeeSelectionMode.ANY_ONE_WITH_SECRET,
                    child: new Text(localizations.anyoneWithSecret),
                  ),
                  DropdownMenuItem(
                    value: PayeeSelectionMode.CHOOSE_FROM_CONTACTS,
                    child: new Text(localizations.chooseFromContacts),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ]);

    if (_payeeSelectionMode == PayeeSelectionMode.ANY_ONE_WITH_SECRET) {
      children.addAll([
        const SizedBox(height: 16.0),
        TextFormField(
          controller: _secretController,
          decoration: InputDecoration(
            labelText: localizations.secretPin,
          ),
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
        ),
      ]);
    }

    if (_payeeSelectionMode == PayeeSelectionMode.CHOOSE_FROM_CONTACTS) {
      children.addAll([
        const SizedBox(height: 16.0),
        TextField(
          readOnly: true,
          controller: _payeeController,
          decoration: InputDecoration(
            labelText: localizations.payees,
            suffix: GestureDetector(
              onTap: () => _choosePayees(context),
              child: Icon(Icons.contacts),
            ),
          ),
          textInputAction: TextInputAction.done,
        ),
      ]);
    }

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
      return;
    }
    if (_payeeSelectionMode == PayeeSelectionMode.ANY_ONE_WITH_SECRET && isEmpty(_secretController.text)) {
      showError(localizations.fieldIsMandatory(localizations.secretPin));
      return;
    }
    if (_payeeSelectionMode == PayeeSelectionMode.CHOOSE_FROM_CONTACTS && _payees.isEmpty) {
      showError(localizations.fieldIsMandatory(localizations.payees));
      return;
    }
    if (!_formKey.currentState.validate()) {
      print("Validation failure");
      return;
    }
    AccountService.updatePreferences(
      appConfiguration,
      appConfiguration.account,
      currency: _currency,
    );
    List<PaymentAuthorizationPayeeInput> payees = [];
    if (_payeeSelectionMode == PayeeSelectionMode.ANY_ONE_WITH_SECRET) {
      payees = [
        PaymentAuthorizationPayeeInput(
          secret: _secretController.text,
        ),
      ];
    } else if (_payeeSelectionMode == PayeeSelectionMode.CHOOSE_FROM_CONTACTS) {
      payees = _payees
          .map(
            (p) => PaymentAuthorizationPayeeInput(
              payeeProxyId: p.proxyId,
              customerEmail: p.email,
              customerPhone: p.phoneNumber,
              secret: RandomUtils.randomSecret(),
            ),
          )
          .toList();
    }
    PaymentAuthorizationInput result = PaymentAuthorizationInput(
      currency: _currency,
      amount: double.parse(_amountController.text),
      message: _messageController.text,
      payees: payees,
    );
    print("Accepting $result");
    Navigator.of(context).pop(result);
  }

  void _choosePayees(BuildContext context) async {
    print("Choose Payees");
    final contacts = await Navigator.push(
      context,
      new MaterialPageRoute<Set<ContactEntity>>(
        builder: (context) => ContactsPage.multiSelection(
          appConfiguration,
        ),
      ),
    );
    if (contacts != null) {
      setState(() {
        _payees = contacts;
      });
    }
  }

  String _payeesAsString() {
    return _payees.map((p) => p.name ?? p.proxyId.id ?? p.phoneNumber ?? p.email).join(", ");
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
