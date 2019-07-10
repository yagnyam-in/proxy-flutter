import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';

import 'config/app_configuration.dart';

enum LoginMode { EmailLink, GoogleSignIn }

class WelcomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const WelcomePage(this.appConfiguration, {Key key}) : super(key: key);

  @override
  _WelcomePageState createState() {
    return _WelcomePageState(appConfiguration);
  }
}

class _WelcomePageState extends State<WelcomePage> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  LoginMode _loginMode;

  _WelcomePageState(this.appConfiguration);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loginMode == LoginMode.EmailLink) {}
    return _welcomePage(context);
  }

  Widget _welcomePage(BuildContext context) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _welcomeHeader(context),
            _loginButtons(context),
          ],
        ),
      );

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
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                  shape: StadiumBorder(),
                  child: Text(
                    localizations.signInWithGoogle,
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _googleSignIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _googleSignIn() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser firebaseUser = await _auth.signInWithCredential(credential);
    if (firebaseUser != null) {
      UserEntity appUser = await ServiceFactory.registerService().registerUser(firebaseUser);
      print("signed in " + appUser.name);
      AppConfigurationBloc.instance.refresh();
    } else {
      print("failed to signIn");
    }
  }
}
