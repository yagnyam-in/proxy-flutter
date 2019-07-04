import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/user_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';

class ManageAccountPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final AppConfigurationUpdater appConfigurationUpdater;

  ManageAccountPage(
    this.appConfiguration, {
    Key key,
    @required this.appConfigurationUpdater,
  }) : super(key: key) {
    print("Constructing ManageAccountPage");
  }

  @override
  _ManageAccountPageState createState() => _ManageAccountPageState(appConfiguration, appConfigurationUpdater);
}

class _ManageAccountPageState extends LoadingSupportState<ManageAccountPage> {
  AppConfiguration appConfiguration;
  final AppConfigurationUpdater appConfigurationUpdater;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passPhraseController = TextEditingController();

  FocusNode actionButtonFocusNode;

  bool _showNewAccountOption = false;
  bool loading = false;
  int retryCount = 0;

  _ManageAccountPageState(this.appConfiguration, this.appConfigurationUpdater) {
    assert(appConfiguration != null);
    assert(appConfiguration.firebaseUser != null);
    assert(appConfiguration.appUser != null);
  }

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
      duration: Duration(seconds: 6),
    ));
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().start();
    actionButtonFocusNode = FocusNode();
  }

  @override
  void dispose() {
    actionButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          appConfiguration.account == null ? localizations.newAccountTitle : localizations.recoverAccountTitle,
        ),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 8.0),
                Text(
                  appConfiguration.account == null
                      ? localizations.newPassPhraseDescription
                      : localizations.recoverPassPhraseDescription,
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  autofocus: true,
                  controller: passPhraseController,
                  decoration: InputDecoration(
                    labelText: localizations.passPhrase,
                    helperText: localizations.passPhraseHint,
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (val) => FocusScope.of(context).requestFocus(actionButtonFocusNode),
                  validator: (value) => _passphraseIdValidator(localizations, value),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    // const Spacer(),
                    RaisedButton(
                      focusNode: actionButtonFocusNode,
                      onPressed: () => _submit(context),
                      child: Text(localizations.setupProxyButtonLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                if (_showNewAccountOption)
                  FlatButton(
                    child: Text(localizations.createNewAccountButtonLabel),
                    onPressed: () => _createAnotherAccount(context),
                  ),
              ],
            ),
          ),
        ),
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
      await AppConfiguration.storePassPhrase(passPhrase);

      AccountEntity account = await accountService.setupMasterProxy(appConfiguration.account, passPhrase);
      appConfiguration = appConfiguration.copy(
        account: account,
        passPhrase: passPhrase,
      );
      appConfigurationUpdater(appConfiguration);
    }
  }

  void _createAccount(BuildContext context) async {
    print("Create Account");
    await AppConfiguration.storePassPhrase(passPhrase);

    AccountEntity account = await accountService.createAccount(encryptionKey: passPhrase);
    UserEntity appUser = await UserStore.forUser(appConfiguration.firebaseUser).saveUser(
      appConfiguration.appUser.copy(accountId: account.accountId),
    );
    account = await accountService.setupMasterProxy(account, passPhrase);
    appConfiguration = appConfiguration.copy(
      account: account,
      appUser: appUser,
      passPhrase: passPhrase,
    );
    appConfigurationUpdater(appConfiguration);
  }
}
