import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/link_text_span.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/service_factory.dart';

class EmailLinkLoginPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  EmailLinkLoginPage(
    this.appConfiguration, {
    Key key,
  }) : super(key: key) {
    print("Constructing EmailLinkLoginPage");
  }

  @override
  _EmailLinkLoginPageState createState() => _EmailLinkLoginPageState(appConfiguration);
}

class _EmailLinkLoginPageState extends LoadingSupportState<EmailLinkLoginPage> with WidgetsBindingObserver {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Timer _timerLink;
  String loginFailedMessage;
  String status;
  bool loading = false;

  _EmailLinkLoginPageState(this.appConfiguration);

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void initState() {
    super.initState();
    initDynamicLinks();
  }

  void initDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      _handleDynamicLinks(deepLink);
    }
    FirebaseDynamicLinks.instance.onLink(onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;
      if (deepLink != null) {
        _handleDynamicLinks(deepLink);
      }
    }, onError: (OnLinkErrorException e) async {
      print('initDynamicLinks: ${e.message}');
    });
  }

  Future<void> _handleDynamicLinks(Uri link) async {
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
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: _SignUpForm(
            sharedPreferences: appConfiguration.preferences,
            status: status,
          ),
        ),
      ),
    );
  }

  void _login(Uri loginLink) async {
    try {
      invoke(() async {
        final authResult = await FirebaseAuth.instance.signInWithEmailAndLink(
          email: appConfiguration.preferences.getString('email'),
          link: loginLink.toString(),
        );
        FirebaseUser firebaseUser = authResult?.user;
        if (firebaseUser != null) {
          await ServiceFactory.registerService().registerUser(firebaseUser);
          AppConfigurationBloc.instance.refresh();
        }
      }, name: 'Login With Link', onError: () => showError(loginFailedMessage));
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
  bool _loading = false;
  bool _agreedToTOS = false;
  bool _loginEnabled = true;
  bool _lockTOS = false;
  Timer _timerToEnableLoginButton;
  bool loading = false;
  String status;

  FocusNode _tcFocusNode;
  FocusNode _loginFocusNode;

  _SignUpFormState({
    @required this.sharedPreferences,
    this.status,
  }) : _emailController = TextEditingController(
          text: sharedPreferences.getString(EMAIL_PREFERENCE_NAME),
        );

  @override
  void initState() {
    super.initState();
    _tcFocusNode = FocusNode();
    _loginFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return BusyChildWidget(
      loading: _loading,
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 16.0),
            Text(
              localizations.loginPageDescription,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: localizations.emailInputLabel),
              validator: (String value) {
                if (value == null || value.isEmpty) {
                  return localizations.fieldIsMandatory(localizations.thisField);
                }
                return null;
              },
              onFieldSubmitted: (val) => FocusScope.of(context).requestFocus(_tcFocusNode),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 32.0),
            termsAndConditions(context),
            const SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Checkbox(
                  value: _agreedToTOS,
                  onChanged: _lockTOS ? null : _setAgreedToTOS,
                ),
                GestureDetector(
                  onTap: _lockTOS ? null : () => _setAgreedToTOS(!_agreedToTOS),
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
                focusNode: _loginFocusNode,
                onPressed: () async {
                  if (!_loginEnabled) {
                    _showSnackBar(localizations.youNeedToWaitForMinuteToRetry);
                    return;
                  }
                  if (_formKey.currentState.validate()) {
                    _register(context);
                  }
                },
                child: Text(localizations.verifyButtonLabel),
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
    _tcFocusNode.dispose();
    _loginFocusNode.dispose();
    if (_timerToEnableLoginButton != null) {
      _timerToEnableLoginButton.cancel();
    }
    super.dispose();
  }

  _showSnackBar(String message) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> _register(BuildContext context) async {
    FocusScope.of(context).requestFocus(_loginFocusNode);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!_agreedToTOS) {
      _showSnackBar(localizations.youMustAgreeTermsAndConditions);
      print('T&C not agreed');
      return;
    }

    invoke(() async {
      var preferences = await SharedPreferences.getInstance();
      preferences.setString(EMAIL_PREFERENCE_NAME, _emailController.text);

      await FirebaseAuth.instance.sendSignInWithEmailLink(
        email: _emailController.text,
        url: '${UrlConfig.APP_BACKEND}/actions/auth',
        handleCodeInApp: true,
        iOSBundleID: Constants.IOS_BUNDLE_ID,
        androidPackageName: Constants.ANDROID_PACKAGE_NAME,
        androidInstallIfNotAvailable: true,
        androidMinimumVersion: "12",
      );

      _timerToEnableLoginButton = new Timer(const Duration(minutes: 1), () {
        setState(() => _loginEnabled = true);
      });
      _showSnackBar(localizations.checkYourMailForLoginLink);
      setState(() {
        _lockTOS = true;
        _loginEnabled = false;
        status = localizations.checkYourMailForLoginLink;
        print('Setting status to $status');
      });
    }, name: 'Send Login Link', onError: () => _showSnackBar(localizations.somethingWentWrong));
  }
}
