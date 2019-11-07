import 'package:flutter/material.dart';
import 'package:promo/localizations.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:quiver/strings.dart';

class CurrencyInputFormField extends StatefulWidget {
  final String selectedCurrency;
  final String preferredCurrency;
  final Set<String> validCurrencies;
  final ValueChanged<String> onChanged;

  CurrencyInputFormField({
    this.selectedCurrency,
    this.preferredCurrency,
    @required this.validCurrencies,
    @required this.onChanged,
  });

  @override
  CurrencyInputFormFieldState createState() {
    String effectiveCurrency = selectedCurrency;
    if (effectiveCurrency == null) {
      if (validCurrencies.length == 1) {
        effectiveCurrency = validCurrencies.first;
      } else {
        effectiveCurrency = validCurrencies.firstWhere((currency) => currency == preferredCurrency, orElse: () => null);
      }
    }
    if (effectiveCurrency != null) {
      onChanged(effectiveCurrency);
    }
    return CurrencyInputFormFieldState(effectiveCurrency);
  }

  static Widget forCurrencies({
    @required String preferredCurrency,
    @required Future<Set<String>> validCurrenciesFuture,
    @required ValueChanged<String> onChanged,
  }) {
    return futureBuilder(
      name: 'Currency Input',
      future: validCurrenciesFuture,
      builder: (BuildContext context, Set<String> validCurrencies) {
        return CurrencyInputFormField(
          preferredCurrency: preferredCurrency,
          validCurrencies: validCurrencies,
          onChanged: onChanged,
        );
      },
    );
  }
}

class CurrencyInputFormFieldState extends State<CurrencyInputFormField> {
  String _value;

  CurrencyInputFormFieldState(String initialValue) : _value = initialValue;

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return FormField(
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: localizations.currency,
          ),
          isEmpty: isEmpty(_value),
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton(
              value: _value,
              isDense: true,
              onChanged: (String newValue) {
                setState(() {
                  _value = newValue;
                  state.didChange(newValue);
                });
                widget.onChanged(newValue);
              },
              items: widget.validCurrencies.map((String value) {
                return new DropdownMenuItem(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
