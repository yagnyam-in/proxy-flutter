import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/authorizations_helper.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/email_authorization_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/email_authorization_entity.dart';
import 'package:proxy_flutter/widgets/widget_helper.dart';

import 'authorize_email_page.dart';
import 'authorize_phone_number_page.dart';
import 'db/phone_number_authorization_store.dart';
import 'model/phone_number_authorization_entity.dart';
import 'services/enticement_factory.dart';
import 'utils/data_validations.dart';
import 'widgets/async_helper.dart';
import 'widgets/authorization_card.dart';
import 'widgets/enticement_helper.dart';
import 'widgets/loading.dart';

class AuthorizationsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const AuthorizationsPage(this.appConfiguration, {Key key}) : super(key: key);

  @override
  AuthorizationsPageState createState() {
    return AuthorizationsPageState(appConfiguration);
  }
}

class AuthorizationsPageState extends LoadingSupportState<AuthorizationsPage>
    with AuthorizationsHelper, EnticementHelper {
  final AppConfiguration appConfiguration;
  final EmailAuthorizationStore _emailAuthorizationStore;
  final PhoneNumberAuthorizationStore _phoneNumberAuthorizationStore;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<List<EmailAuthorizationEntity>> _emailAuthorizationsStream;
  Stream<List<PhoneNumberAuthorizationEntity>> _phoneNumberAuthorizationsStream;
  bool loading = false;

  AuthorizationsPageState(this.appConfiguration)
      : _emailAuthorizationStore = EmailAuthorizationStore(appConfiguration),
        _phoneNumberAuthorizationStore = PhoneNumberAuthorizationStore(appConfiguration);

  @override
  void initState() {
    super.initState();
    _emailAuthorizationsStream = _emailAuthorizationStore.subscribeForAuthorizations();
    _phoneNumberAuthorizationsStream = _phoneNumberAuthorizationStore.subscribeForAuthorizations();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.authorizationsTitle),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return streamBuilder(
                name: "Email Authorization Loading",
                stream: _emailAuthorizationsStream,
                builder: (context, authorizations) => _emailAuthorizations(context, authorizations),
              );
            } else {
              return streamBuilder(
                name: "Phone Authorizations Loading",
                stream: _phoneNumberAuthorizationsStream,
                loadingWidget: SizedBox.shrink(),
                builder: (context, authorizations) => _phoneNumberAuthorizations(context, authorizations),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _verifyPhoneOrEmail(context),
        icon: Icon(Icons.add),
        label: Text(localizations.verifyFabLabel),
      ),
    );
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _emailAuthorizations(BuildContext context, List<EmailAuthorizationEntity> authorizations) {
    print("email authorizations : $authorizations");
    if (authorizations.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          enticementCard(context, EnticementFactory.noEmailAuthorizations, cancellable: false),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: authorizations.expand((authorization) {
        return [
          const SizedBox(height: 4.0),
          authorizationCard(context, emailAuthorization: authorization),
        ];
      }).toList(),
    );
  }

  Widget _phoneNumberAuthorizations(BuildContext context, List<PhoneNumberAuthorizationEntity> authorizations) {
    print("phone authorizations : $authorizations");
    if (authorizations.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          enticementCard(context, EnticementFactory.noPhoneNumberAuthorizations, cancellable: false),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: authorizations.expand((authorization) {
        return [
          const SizedBox(height: 4.0),
          authorizationCard(context, phoneNumberAuthorization: authorization),
        ];
      }).toList(),
    );
  }

  Widget authorizationCard(
    BuildContext context, {
    EmailAuthorizationEntity emailAuthorization,
    PhoneNumberAuthorizationEntity phoneNumberAuthorization,
  }) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        onTap: () => _launchAuthorization(
          context,
          emailAuthorization: emailAuthorization,
          phoneNumberAuthorization: phoneNumberAuthorization,
        ),
        child: AuthorizationCard(
          emailAuthorization: emailAuthorization,
          phoneNumberAuthorization: phoneNumberAuthorization,
        ),
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => _archiveAuthorization(
            context,
            emailAuthorization: emailAuthorization,
            phoneNumberAuthorization: phoneNumberAuthorization,
          ),
        ),
      ],
    );
  }

  Future<void> _archiveAuthorization(
    BuildContext context, {
    EmailAuthorizationEntity emailAuthorization,
    PhoneNumberAuthorizationEntity phoneNumberAuthorization,
  }) async {
    if (emailAuthorization != null) {
      await _emailAuthorizationStore.deleteAuthorization(emailAuthorization);
    }
    if (phoneNumberAuthorization != null) {
      await _phoneNumberAuthorizationStore.deleteAuthorization(phoneNumberAuthorization);
    }
  }

  Future<void> _launchAuthorization(
    BuildContext context, {
    EmailAuthorizationEntity emailAuthorization,
    PhoneNumberAuthorizationEntity phoneNumberAuthorization,
  }) async {
    if (emailAuthorization != null) {
      return Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => AuthorizeEmailPage.forAuthorization(
            appConfiguration,
            emailAuthorization,
          ),
          fullscreenDialog: true,
        ),
      );
    }
    if (phoneNumberAuthorization != null) {
      return Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => AuthorizePhoneNumberPage.forAuthorization(
            appConfiguration,
            phoneNumberAuthorization,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  Future<void> _verifyPhoneOrEmail(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String mailOrPhoneNumber = await acceptInputDialog(
      context,
      pageTitle: localizations.verifyFabLabel,
      fieldName: localizations.emailOrPhoneNumber,
    );
    if (isPhoneNumber(mailOrPhoneNumber)) {
      await verifyPhoneNumber(context, mailOrPhoneNumber);
    } else if (isEmailAddress(mailOrPhoneNumber)) {
      await verifyEmail(context, mailOrPhoneNumber);
    } else {
      showToast(localizations.invalidEmailOrPhoneNumber);
    }
  }

  @override
  Future<void> createAccountAndDeposit(BuildContext context) async {
    print("How is createAccountAndDeposit invoked");
    return null;
  }

  @override
  Future<void> createPaymentAuthorization(BuildContext context) async {
    print("How is createPaymentAuthorization invoked");
    return null;
  }
}
