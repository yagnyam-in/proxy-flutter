import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/link_text_span.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef LoginCallback = void Function(FirebaseUser firebaseUser);

class LoginPage extends StatefulWidget {
  final LoginCallback loginCallback;
  final SharedPreferences sharedPreferences;

  LoginPage({
    Key key,
    @required this.loginCallback,
    @required this.sharedPreferences,
  }) : super(key: key) {
    print("Constructing LoginPage");
  }

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String loginFailedMessage;
  String status;

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("didChangeAppLifecycleState (ProxyAppState)");
      _handleDynamicLinks();
    }
  }

  Future<void> _handleDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    Uri link = data?.link;
    if (link == null) return;
    print('link = $link');
    bool isLoginLink = await FirebaseAuth.instance.isSignInWithEmailLink(link.toString());
    if (isLoginLink) {
      _login(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    loginFailedMessage = localizations.loginFailedMessage;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.loginPageTitle),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: _SignUpForm(
          sharedPreferences: widget.sharedPreferences,
          status: status,
        ),
      ),
    );
  }

  void _login(Uri loginLink) async {
    try {
      var preferences = await SharedPreferences.getInstance();
      FirebaseUser user = await FirebaseAuth.instance.signInWithEmailAndLink(
        email: preferences.getString('email'),
        link: loginLink.toString(),
      );
      if (user != null) {
        widget.loginCallback(user);
      }
    } catch (e) {
      setState(() {
        status = loginFailedMessage ?? 'Login Failed';
      });
      print("failed to login: $e");
    }
  }
}

class _SignUpForm extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final String status;

  const _SignUpForm({
    Key key,
    @required this.sharedPreferences,
    this.status,
  }) : super(key: key);

  @override
  _SignUpFormState createState() {
    return _SignUpFormState(
      sharedPreferences: sharedPreferences,
      status: status,
    );
  }
}

class _SignUpFormState extends LoadingSupportState<_SignUpForm> {
  static const String EMAIL_PREFERENCE_NAME = 'email';
  final SharedPreferences sharedPreferences;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController;
  bool _agreedToTOS = true;
  String status;
  bool _loading = false;

  _SignUpFormState({
    @required this.sharedPreferences,
    this.status,
  }) : _emailController = TextEditingController(
          text: sharedPreferences.getString(EMAIL_PREFERENCE_NAME),
        );

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return BusyChildWidget(
      loading: _loading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16.0),
            Text(
              localizations.loginPageDescription,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: localizations.emailInputLabel),
              validator: (String value) {
                if (value == null || value.isEmpty) {
                  return localizations.fieldIsMandatory(localizations.thisField);
                }
                return null;
              },
            ),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    invoke(() => _register(context));
                  }
                },
                child: Text(localizations.loginButtonLabel),
              ),
            ),
            Container(
              alignment: Alignment.center,
              child: Text(
                status ?? '',
                style: Theme.of(context).textTheme.subtitle,
              ),
            )
          ],
        ),
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

  void _setAgreedToTOS(bool newValue) {
    setState(() {
      _agreedToTOS = newValue;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register(BuildContext context) async {
    if (!_agreedToTOS) {
      print('T&C not agreed');
      return;
    }
    var preferences = await SharedPreferences.getInstance();
    preferences.setString(EMAIL_PREFERENCE_NAME, _emailController.text);

    await FirebaseAuth.instance.sendSignInWithEmailLink(
      email: _emailController.text,
      url: '${UrlConfig.APP_BACKEND}/actions/auth',
      handleCodeInApp: true,
      iOSBundleID: 'in.yagnyam.proxy',
      androidPackageName: Constants.ANDROID_PACKAGE_NAME,
      androidInstallIfNotAvailable: true,
      androidMinimumVersion: "12",
    );

    setState(() {
      status = ProxyLocalizations.of(context).checkYourMailForLoginLink;
      print('Setting status to $status');
    });
  }
}
