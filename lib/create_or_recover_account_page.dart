import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';

import 'config/app_configuration.dart';
import 'db/user_store.dart';
import 'model/account_entity.dart';
import 'services/account_service.dart';
import 'widgets/async_helper.dart';
import 'widgets/loading.dart';

enum LoginMode { EmailLink, GoogleSignIn }

class CreateOrRecoverAccount extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const CreateOrRecoverAccount(this.appConfiguration, {Key key}) : super(key: key);

  @override
  _CreateOrRecoverAccountState createState() {
    return _CreateOrRecoverAccountState(appConfiguration);
  }
}

class _CreateOrRecoverAccountState extends LoadingSupportState<CreateOrRecoverAccount> {
  final AppConfiguration appConfiguration;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passPhraseController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  FocusNode actionButtonFocusNode;

  bool _showNewAccountOption = false;
  bool loading = false;
  int retryCount = 0;

  _CreateOrRecoverAccountState(this.appConfiguration);

  AccountService get accountService {
    return AccountService(
      firebaseUser: appConfiguration.firebaseUser,
      appUser: appConfiguration.appUser,
    );
  }

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  void showLongInfo(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().warmUpBackends();
    actionButtonFocusNode = FocusNode();
  }

  @override
  void dispose() {
    actionButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: BusyChildWidget(
        loading: loading,
        child: Center(
          child: _createOrRecoverAccount(context),
        ),
      ),
    );
  }

  Widget _createOrRecoverAccount(BuildContext context) => SingleChildScrollView(
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
        Text(
          appConfiguration.account == null ? localizations.newAccountTitle : localizations.recoverAccountTitle,
          style: theme.textTheme.subhead.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(
          height: 5.0,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            appConfiguration.account == null
                ? localizations.newPassPhraseDescription
                : localizations.recoverPassPhraseDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _loginButtons(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ThemeData theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
            child: TextFormField(
              autofocus: true,
              controller: passPhraseController,
              decoration: InputDecoration(
                labelText: localizations.passPhrase,
                helperText: localizations.passPhraseHint,
              ),
              keyboardType: TextInputType.text,
              // TODO: Change to Visible Password Type
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (val) => FocusScope.of(context).requestFocus(actionButtonFocusNode),
              validator: (value) => _passphraseIdValidator(localizations, value),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 30.0),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  focusNode: actionButtonFocusNode,
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                  shape: StadiumBorder(),
                  child: Text(
                    appConfiguration.account == null
                        ? localizations.setupPassPhraseButtonLabel
                        : localizations.recoverPassPhraseButtonLabel,
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _submit(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          if (_showNewAccountOption)
            FlatButton(
              child: Text(
                localizations.createNewAccountButtonLabel,
                style: theme.textTheme.subhead.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.secondary,
                  decoration: TextDecoration.underline,
                ),
              ),
              onPressed: () => _createAnotherAccount(context),
            ),
        ],
      ),
    );
  }

  bool _isValidPassphrase(String passphrase) {
    return passphrase != null && passphrase.length >= 8 && passphrase.length <= 64;
  }

  String _passphraseIdValidator(ProxyLocalizations localizations, String passphrase) {
    if (passphrase.isEmpty) {
      return localizations.fieldIsMandatory(localizations.passPhrase);
    } else if (!_isValidPassphrase(passphrase)) {
      return localizations.passPhrase;
    }
    return null;
  }

  void _createAnotherAccount(BuildContext context) {
    print("Create Another Account");
    if (_formKey.currentState.validate()) {
      try {
        invoke(() async => _createAccount(context),
            name: 'Create Another Account', onError: () => _somethingWentWrong(context));
      } catch (e) {
        print("Error Creating new Account: $e");
        showError(ProxyLocalizations.of(context).somethingWentWrong);
      }
    } else {
      print("Validation failure");
    }
  }

  String get passPhrase => passPhraseController.text;

  void _submit(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).requestFocus(actionButtonFocusNode);
      showLongInfo(localizations.heavyOperation);

      if (appConfiguration.account != null) {
        invoke(() async => _recoverAccount(context),
            name: 'Recover Account', onError: () => _somethingWentWrong(context));
      } else {
        invoke(() async => _createAccount(context),
            name: 'Create Account', onError: () => _somethingWentWrong(context));
      }
    } else {
      print("Validation failure");
    }
  }

  void _somethingWentWrong(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    showError(localizations.somethingWentWrong);
  }

  void _recoverAccount(BuildContext context) async {
    print("Recover Account");
    bool valid = await accountService.validateEncryptionKey(
      account: appConfiguration.account,
      encryptionKey: passPhrase,
    );
    if (!valid) {
      retryCount++;
      print("Wrong Pass Phrase");
      ProxyLocalizations localizations = ProxyLocalizations.of(context);
      showError(localizations.wrongPassPhraseDescription);
      if (retryCount >= 3) {
        setState(() {
          _showNewAccountOption = true;
        });
      }
    } else {
      await accountService.setupMasterProxy(appConfiguration.account, passPhrase);
      AppConfigurationBloc.instance.refresh(passPhrase: passPhrase);
    }
  }

  void _createAccount(BuildContext context) async {
    print("Create Account");

    AccountEntity account = await accountService.createAccount(encryptionKey: passPhrase);
    await UserStore.forUser(appConfiguration.firebaseUser).saveUser(
      appConfiguration.appUser.copy(accountId: account.accountId),
    );
    account = await accountService.setupMasterProxy(account, passPhrase);
    AppConfigurationBloc.instance.refresh(passPhrase: passPhrase);
  }
}
