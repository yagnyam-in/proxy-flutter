import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/terms.dart';

import 'app_configuration_bloc.dart';
import 'service_factory.dart';

mixin LoginHelper {
  void showError(String message);

  void showMessage(String message);

  AppConfiguration get appConfiguration;

  static const _EMAIL_PREFERENCE_NAME = "loginEmail";
  static const _PHONE_NUMBER_PREFERENCE_NAME = "loginPhoneNumber";
  static const _PHONE_VERIFICATION_ID_PREFERENCE_NAME = "loginPhoneVerificationId";

  Future<void> triggerPhoneLogin(
    BuildContext context,
    String phoneNumber, {
    @required VoidCallback verificationFailed,
    @required VoidCallback codeSent,
  }) async {
    await appConfiguration.preferences.setString(_PHONE_NUMBER_PREFERENCE_NAME, phoneNumber);
    return FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 30),
      verificationCompleted: _verificationCompleted,
      verificationFailed: (authException) {
        print("Phone Verification failed: $authException");
        verificationFailed();
      },
      codeSent: (String verificationId, [int forceResendingToken]) {
        appConfiguration.preferences.setString(_PHONE_VERIFICATION_ID_PREFERENCE_NAME, verificationId);
        codeSent();
      },
      codeAutoRetrievalTimeout: _codeAutoRetrievalTimeout,
    );
  }

  Future<void> triggerEmailLogin(
    BuildContext context,
    String email,
  ) async {
    await appConfiguration.preferences.setString(_EMAIL_PREFERENCE_NAME, email);
    return FirebaseAuth.instance.sendSignInWithEmailLink(
      email: email,
      url: '${UrlConfig.APP_BACKEND}/actions/auth',
      handleCodeInApp: true,
      iOSBundleID: Constants.IOS_BUNDLE_ID,
      androidPackageName: Constants.ANDROID_PACKAGE_NAME,
      androidInstallIfNotAvailable: true,
      androidMinimumVersion: "12",
    );
  }

  void _verificationCompleted(AuthCredential credentials) async {
    final authResult = await FirebaseAuth.instance.signInWithCredential(credentials);
    await continueLogin(authResult);
  }

  void _codeAutoRetrievalTimeout(String verificationId) {
    print("_codeAutoRetrievalTimeout");
    appConfiguration.preferences.setString(_PHONE_VERIFICATION_ID_PREFERENCE_NAME, verificationId);
  }

  void loginWithEmailLink(Uri loginLink) async {
    final AuthResult authResult = await FirebaseAuth.instance.signInWithEmailAndLink(
      email: appConfiguration.preferences.getString(_EMAIL_PREFERENCE_NAME),
      link: loginLink.toString(),
    );
    await continueLogin(authResult);
  }

  void googleSignIn(BuildContext context) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final AuthResult authResult = await FirebaseAuth.instance.signInWithCredential(credential);
    continueLogin(authResult);
  }

  Future<void> continueLogin(AuthResult authResult) async {
    FirebaseUser firebaseUser = authResult?.user;
    if (firebaseUser != null) {
      UserEntity appUser = await ServiceFactory.registerService().registerUser(firebaseUser);
      print("signed in " + appUser.name);
    } else {
      print("failed to login");
    }
    AppConfigurationBloc.instance.refresh();
  }

  Future<void> handleLoginDynamicLinks(Uri link) async {
    if (link == null) return;
    print('link = $link');
    bool isLoginLink = await FirebaseAuth.instance.isSignInWithEmailLink(link.toString());
    if (isLoginLink) {
      loginWithEmailLink(link);
    }
  }

  Future<bool> acceptTermsAndConditions(BuildContext context) {
    return Future.value(true);
    return Navigator.push(
      context,
      new MaterialPageRoute<bool>(
        builder: (context) => TermsAndConditionsPage(),
        fullscreenDialog: true,
      ),
    );
  }
}
