import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/email_authorization_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/email_authorization_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';

typedef SecretCallback = void Function(String secret);

class AuthorizeEmailPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final EmailAuthorizationEntity authorization;
  final String authorizationId;
  final String secret;

  AuthorizeEmailPage.forId(
    this.appConfiguration, {
    @required this.authorizationId,
    this.secret,
    Key key,
  })  : authorization = null,
        super(key: key);

  AuthorizeEmailPage.forAuthorization(this.appConfiguration, this.authorization, {Key key})
      : authorizationId = authorization.authorizationId,
        secret = null,
        super(key: key);

  @override
  AuthorizeEmailPageState createState() {
    return AuthorizeEmailPageState(
      appConfiguration: appConfiguration,
      authorizationId: authorizationId,
    );
  }
}

class AuthorizeEmailPageState extends LoadingSupportState<AuthorizeEmailPage> with ProxyUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppConfiguration appConfiguration;
  final String authorizationId;

  Stream<EmailAuthorizationEntity> _emailAuthorizationStream;
  bool loading = false;

  AuthorizeEmailPageState({
    @required this.appConfiguration,
    @required this.authorizationId,
  });

  @override
  void initState() {
    super.initState();
    _emailAuthorizationStream = EmailAuthorizationStore(appConfiguration).subscribeForAuthorization(authorizationId);
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  Future<void> _verifyEmail(String secret) async {
    print("Verify email");
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    showToast(localizations.verificationInProgress);
    final authorization = await invoke(
      () async => ServiceFactory.emailAuthorizationService(appConfiguration).verifyAuthorizationChallenge(
        authorizationEntity: widget.authorization ??
            await EmailAuthorizationStore(appConfiguration).fetchAuthorizationById(authorizationId),
        secret: secret,
      ),
      name: 'Verify Email',
    );
    if (authorization == null || !authorization.authorized) {
      showToast(localizations.emailAuthorizationFailedDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.authorizeEmail + appConfiguration.proxyUniverseSuffix),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: streamBuilder(
            name: "Email Authorization Fetcher",
            initialData: widget.authorization,
            stream: _emailAuthorizationStream,
            emptyMessage: localizations.invalidEmailAuthorization,
            builder: (context, authorization) => _AuthorizeEmailPageBody(
              scaffoldKey: _scaffoldKey,
              appConfiguration: appConfiguration,
              authorization: authorization,
              secretCallback: _verifyEmail,
              secret: widget.secret,
              key: ObjectKey(authorization),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorizeEmailPageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final EmailAuthorizationEntity authorization;
  final SecretCallback secretCallback;
  final String secret;

  const _AuthorizeEmailPageBody({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.authorization,
    @required this.secretCallback,
    this.secret,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AuthorizeEmailPageBodyState(
      appConfiguration: appConfiguration,
      authorization: authorization,
      secret: secret,
    );
  }
}

class _AuthorizeEmailPageBodyState extends State<_AuthorizeEmailPageBody> {
  final AppConfiguration appConfiguration;
  final EmailAuthorizationEntity authorization;
  bool _verificationTriggered = false;
  final String secret;

  _AuthorizeEmailPageBodyState({
    Key key,
    @required this.appConfiguration,
    @required this.authorization,
    this.secret,
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyEmail(context));
  }

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
            localizations.customerEmail,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Text(
            authorization.email,
            style: themeData.textTheme.title,
          ),
        ),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.status,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Text(
            authorization.authorized ? localizations.verified : localizations.notVerified,
            style: themeData.textTheme.title,
          ),
        ),
      ],
    );
  }

  Future<void> _verifyEmail(BuildContext context) async {
    if (_verificationTriggered || authorization.authorized) {
      return;
    }
    print("Verify email");
    _verificationTriggered = true;
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (isEmpty(secret)) {
      _showToast(localizations.invalidSecret);
      return;
    }
    widget.secretCallback(secret);
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
