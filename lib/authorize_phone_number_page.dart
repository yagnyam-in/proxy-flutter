import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/phone_number_authorization_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/phone_number_authorization_entity.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';

import 'services/service_factory.dart';

class AuthorizePhoneNumberPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final PhoneNumberAuthorizationEntity authorization;

  AuthorizePhoneNumberPage.forAuthorization(this.appConfiguration, this.authorization, {Key key}) : super(key: key);

  @override
  AuthorizePhoneNumberPageState createState() {
    return AuthorizePhoneNumberPageState(
      appConfiguration: appConfiguration,
    );
  }
}

class AuthorizePhoneNumberPageState extends LoadingSupportState<AuthorizePhoneNumberPage> with ProxyUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppConfiguration appConfiguration;

  Stream<PhoneNumberAuthorizationEntity> _phoneNumberAuthorizationStream;
  bool loading = false;

  AuthorizePhoneNumberPageState({
    @required this.appConfiguration,
  });

  @override
  void initState() {
    super.initState();
    _phoneNumberAuthorizationStream = PhoneNumberAuthorizationStore(appConfiguration).subscribeForAuthorization(
      widget.authorization.authorizationId,
    );
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
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
          child: streamBuilder(
            name: "Phone Number Authorization Fetcher",
            initialData: widget.authorization,
            stream: _phoneNumberAuthorizationStream,
            emptyMessage: localizations.invalidPhoneNumberAuthorization,
            builder: (context, authorization) => _AuthorizePhoneNumberPageBody(
              scaffoldKey: _scaffoldKey,
              appConfiguration: appConfiguration,
              authorization: authorization,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorizePhoneNumberPageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final PhoneNumberAuthorizationEntity authorization;

  const _AuthorizePhoneNumberPageBody({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.authorization,
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
        if (authorization.authorized) ..._verified(context) else ..._verify(context),
      ],
    );
  }

  List<Widget> _verified(BuildContext context) {
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

  List<Widget> _verify(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
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
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
            textInputAction: TextInputAction.done,
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: [
          RaisedButton(
            onPressed: () => invoke(
              () => _verifyPhoneNumber(context),
              name: 'Verify Phone',
              onError: () => _showMessage(localizations.somethingWentWrong),
            ),
            child: Text(localizations.verifyButtonLabel),
          )
        ],
      ),
    ];
  }

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    if (isEmpty(secretController.text)) {
      _showMessage(localizations.invalidVerificationCode);
      return;
    }
    final authorizationEntity =
        await ServiceFactory.phoneNumberAuthorizationService(appConfiguration).verifyAuthorizationChallenge(
      authorizationEntity: authorization,
      secret: secretController.text,
    );
    if (authorizationEntity != null) {
      setState(() {
        authorization = authorizationEntity;
      });
    }
    if (authorizationEntity == null || !authorizationEntity.authorized) {
      _showMessage(localizations.phoneNumberAuthorizationFailedDescription);
    }
  }

  void _showMessage(String message) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
