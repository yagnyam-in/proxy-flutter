import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:promo/localizations.dart';
import 'package:promo/misc_login_methods_page.dart';
import 'package:promo/services/login_helper.dart';
import 'package:promo/services/service_factory.dart';

import 'config/app_configuration.dart';
import 'widgets/async_helper.dart';
import 'widgets/flat_button_with_icon.dart';
import 'widgets/loading.dart';
import 'widgets/routing_animation.dart';

enum LoginMode { EmailLink, GoogleSignIn }

class WelcomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const WelcomePage(this.appConfiguration, {Key key}) : super(key: key);

  @override
  _WelcomePageState createState() {
    return _WelcomePageState(appConfiguration);
  }
}

class _WelcomePageState extends LoadingSupportState<WelcomePage> with LoginHelper {
  static const String EMAIL_PREFERENCE_NAME = 'email';
  static const String PHONE_NUMBER_PREFERENCE_NAME = 'phoneNumber';

  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  bool loading = false;

  _WelcomePageState(this.appConfiguration);

  @override
  void initState() {
    super.initState();
    initDynamicLinks();
    ServiceFactory.bootService().warmUpBackends();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.getInitialLink().then(
      (dynamicLink) {
        handleLoginDynamicLinks(dynamicLink?.link);
      },
      onError: (e) {
        print('failure getting initial link: $e');
      },
    );
    FirebaseDynamicLinks.instance.onLink(
      onSuccess: (dynamicLink) async {
        handleLoginDynamicLinks(dynamicLink?.link);
      },
      onError: (e) async {
        print('failure getting dynamic link: ${e.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: BusyChildWidget(
        loading: loading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _welcomeHeader(context),
            _loginButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _welcomeHeader(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ThemeData theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Icon(
          Icons.security,
          size: 80.0,
          color: theme.colorScheme.secondary,
        ),
        SizedBox(
          height: 30.0,
        ),
        Text(
          localizations.appWelcomeTitle,
          style: theme.textTheme.subhead.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(
          height: 5.0,
        ),
        Text(
          localizations.appWelcomeSubTitle,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _loginButtons(BuildContext context) {
    bool enableMiscLogin = false;
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
              shape: StadiumBorder(),
              child: Text(
                localizations.signInWithGoogle,
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => _googleSignIn(context),
            ),
          ],
        ),
        if (enableMiscLogin) SizedBox(height: 32.0),
        if (enableMiscLogin) Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButtonWithIcon.withSuffixIcon(
              label: Text(
                localizations.signInWithMailOrMobile,
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(Icons.fast_forward),
              onPressed: () => _signInWithMailOrMobile(context),
            ),
          ],
        ),
      ],
    );
  }

  void _googleSignIn(BuildContext context) async {
    final accepted = await acceptTermsAndConditions(context);
    if (accepted != null && accepted) {
      googleSignIn(context);
    }
  }

  void _signInWithMailOrMobile(BuildContext context) async {
    await Navigator.push(
      context,
      new ScaleRoute(
        page: MiscLoginMethodsPage(
          appConfiguration,
        ),
      ),
    );
  }

  @override
  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }
}
