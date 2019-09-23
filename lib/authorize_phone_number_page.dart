import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/phone_number_authorization_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/phone_number_authorization_entity.dart';
import 'package:proxy_flutter/utils/data_validations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';

import 'services/service_factory.dart';

typedef PhoneNumberNumberCallback = void Function(String phoneNumber);
typedef SecretCallback = void Function(String secret);

class AuthorizePhoneNumberPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final PhoneNumberAuthorizationEntity authorization;
  final String phoneNumber;

  AuthorizePhoneNumberPage.forAuthorization(this.appConfiguration, this.authorization, {Key key})
      : phoneNumber = authorization.phoneNumber,
        super(key: key);

  AuthorizePhoneNumberPage.forPhoneNumber(this.appConfiguration, this.phoneNumber, {Key key})
      : authorization = null,
        super(key: key);

  @override
  AuthorizePhoneNumberPageState createState() {
    return AuthorizePhoneNumberPageState(
      appConfiguration: appConfiguration,
      authorization: authorization,
    );
  }
}

class AuthorizePhoneNumberPageState extends LoadingSupportState<AuthorizePhoneNumberPage> with ProxyUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppConfiguration appConfiguration;
  PhoneNumberAuthorizationEntity authorization;

  Stream<PhoneNumberAuthorizationEntity> _phoneNumberAuthorizationStream;
  bool loading = false;

  AuthorizePhoneNumberPageState({
    @required this.appConfiguration,
    @required this.authorization,
  });

  @override
  void initState() {
    super.initState();
    if (authorization != null) {
      _phoneNumberAuthorizationStream = PhoneNumberAuthorizationStore(appConfiguration).subscribeForAuthorization(
        authorization.authorizationId,
      );
    }
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  void _triggerPhoneNumberVerification(String phoneNumber) async {
    print("Verify Phone $phoneNumber");
    final authorizationEntity = await invoke(
      () => ServiceFactory.phoneNumberAuthorizationService(appConfiguration).authorizePhoneNumber(phoneNumber),
      name: 'Trigger Phone Number Verification',
    );
    if (authorizationEntity != null) {
      setState(() {
        this.authorization = authorizationEntity;
        _phoneNumberAuthorizationStream = PhoneNumberAuthorizationStore(appConfiguration).subscribeForAuthorization(
          authorization.authorizationId,
        );
      });
    }
  }

  Future<void> _verifyPhoneNumber(String secret) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    showToast(localizations.verificationInProgress);
    final authorizationEntity = await invoke(
      () => ServiceFactory.phoneNumberAuthorizationService(appConfiguration).verifyAuthorizationChallenge(
        authorizationEntity: authorization,
        secret: secret,
      ),
      name: 'Verify Phone Number',
    );
    if (authorizationEntity == null || !authorizationEntity.authorized) {
      showToast(localizations.phoneNumberAuthorizationFailedDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.authorizePhoneNumber + appConfiguration.proxyUniverseSuffix),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: (authorization == null)
              ? _AcceptPhoneNumber(
                  scaffoldKey: _scaffoldKey,
                  appConfiguration: appConfiguration,
                  phoneNumber: widget.phoneNumber,
                  phoneNumberNumberCallback: _triggerPhoneNumberVerification,
                )
              : streamBuilder(
                  name: "Phone Number Authorization Fetcher",
                  initialData: authorization,
                  stream: _phoneNumberAuthorizationStream,
                  emptyMessage: localizations.invalidPhoneNumberAuthorization,
                  builder: (context, authorization) => _AuthorizePhoneNumberPageBody(
                    scaffoldKey: _scaffoldKey,
                    appConfiguration: appConfiguration,
                    authorization: authorization,
                    secretCallback: _verifyPhoneNumber,
                    key: ObjectKey(authorization),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AcceptPhoneNumber extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final String phoneNumber;
  final PhoneNumberNumberCallback phoneNumberNumberCallback;

  const _AcceptPhoneNumber({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.phoneNumber,
    @required this.phoneNumberNumberCallback,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AcceptPhoneNumberState(
      appConfiguration: appConfiguration,
      phoneNumber: phoneNumber,
    );
  }
}

class _AcceptPhoneNumberState extends LoadingSupportState<_AcceptPhoneNumber> {
  final AppConfiguration appConfiguration;
  final TextEditingController phoneNumberController;
  bool loading = false;

  _AcceptPhoneNumberState({
    Key key,
    @required this.appConfiguration,
    @required String phoneNumber,
  }) : phoneNumberController = TextEditingController(text: phoneNumber);

  String get phoneNumber => phoneNumberController.text;

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.verified_user, size: 64.0),
        const SizedBox(height: 24.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.customerPhone,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: TextField(
              controller: phoneNumberController,
              maxLines: 1,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        ButtonBar(
          alignment: MainAxisAlignment.spaceAround,
          children: [
            RaisedButton(
              onPressed: () => _verifyPhoneNumber(context),
              child: Text(localizations.verifyButtonLabel),
            )
          ],
        ),
      ],
    );
  }

  void _verifyPhoneNumber(BuildContext context) async {
    print("_verify phone");
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!isPhoneNumber(phoneNumber)) {
      _showToast(localizations.invalidPhoneNumber);
      return;
    }
    widget.phoneNumberNumberCallback(phoneNumber);
  }

  void _showToast(String message) {
    widget.scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class _AuthorizePhoneNumberPageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final PhoneNumberAuthorizationEntity authorization;
  final SecretCallback secretCallback;

  const _AuthorizePhoneNumberPageBody({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.authorization,
    @required this.secretCallback,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AuthorizePhoneNumberPageBodyState(
      appConfiguration: appConfiguration,
      authorization: authorization,
    );
  }
}

class _AuthorizePhoneNumberPageBodyState extends LoadingSupportState<_AuthorizePhoneNumberPageBody> {
  final AppConfiguration appConfiguration;
  PhoneNumberAuthorizationEntity authorization;

  final TextEditingController secretController;
  bool loading = false;

  _AuthorizePhoneNumberPageBodyState({
    Key key,
    @required this.appConfiguration,
    @required this.authorization,
  }) : secretController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.verified_user, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.customerPhone,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Text(
            authorization.phoneNumber,
            style: themeData.textTheme.title,
          ),
        ),
        const SizedBox(height: 24.0),
        if (authorization.authorized) ..._statusWidget(context) else ..._secretWidget(context),
      ],
    );
  }

  List<Widget> _statusWidget(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      Center(
        child: Text(
          localizations.status,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          localizations.verified,
          style: themeData.textTheme.title,
        ),
      ),
    ];
  }

  List<Widget> _secretWidget(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      Center(
        child: Text(
          localizations.challengeIndex,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          authorization.verificationIndex,
          style: themeData.textTheme.title,
        ),
      ),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.enterVerificationCode,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: TextField(
            controller: secretController,
            maxLines: 1,
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            style: themeData.textTheme.title,
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: [
          RaisedButton(
            onPressed: () => _verifyPhoneNumber(context),
            child: Text(localizations.verifyButtonLabel),
          )
        ],
      ),
    ];
  }

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (isEmpty(secretController.text)) {
      _showToast(localizations.invalidVerificationCode);
      return;
    }
    widget.secretCallback(secretController.text);
  }

  void _showToast(String message) {
    widget.scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
