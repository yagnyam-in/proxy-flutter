import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/link_text_span.dart';
import 'package:proxy_flutter/widgets/raised_button_with_icon.dart';

typedef TermsAndConditionsAcceptedCallback = void Function();

class TermsAndConditionsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final TermsAndConditionsAcceptedCallback termsAndConditionsAcceptedCallback;

  TermsAndConditionsPage({Key key, @required this.appConfiguration, @required this.termsAndConditionsAcceptedCallback})
      : super(key: key) {
    print("Constructing TermsAndConditionsPage");
  }

  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).termsAndConditionsPageTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: TermsAndConditionsForm(
            termsAndConditionsAcceptedCallback: widget.termsAndConditionsAcceptedCallback,
          ),
        ),
      ),
    );
  }
}

class TermsAndConditionsForm extends StatefulWidget {
  final TermsAndConditionsAcceptedCallback termsAndConditionsAcceptedCallback;

  TermsAndConditionsForm({@required this.termsAndConditionsAcceptedCallback, Key key}) : super(key: key);

  @override
  _TermsAndConditionsFormState createState() => _TermsAndConditionsFormState();
}

class _TermsAndConditionsFormState extends State<TermsAndConditionsForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _agreedToTOS = true;

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 32.0),
          termsAndConditions(context),
          const SizedBox(height: 16.0),
          Row(
            children: <Widget>[
              Checkbox(
                value: _agreedToTOS,
                onChanged: _setAgreedToTOS,
              ),
              GestureDetector(
                onTap: () => _setAgreedToTOS(!_agreedToTOS),
                child: Text(
                  localizations.agreeTermsAndConditions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // const Spacer(),
              RaisedButton(
                onPressed: _submittable() ? _submit : null,
                child: Text(localizations.start),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget termsAndConditions(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);
    final TextStyle aboutTextStyle = themeData.textTheme.body1;
    final TextStyle linkStyle = themeData.textTheme.body1.copyWith(color: themeData.accentColor);

    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            style: aboutTextStyle,
            text: localizations.readTermsAndConditions,
          ),
          LinkTextSpan(
            style: linkStyle,
            url: localizations.termsAndConditionsURL,
          ),
        ],
      ),
    );
  }

  bool _submittable() {
    return _agreedToTOS;
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      widget.termsAndConditionsAcceptedCallback();
    } else {
      print("Validation failure");
    }
  }

  void _setAgreedToTOS(bool newValue) {
    setState(() {
      _agreedToTOS = newValue;
    });
  }
}
