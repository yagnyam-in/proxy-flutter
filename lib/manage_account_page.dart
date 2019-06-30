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

typedef ManageAccountCallback = void Function(AppConfiguration appConfiguration);

class ManageAccountPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ManageAccountCallback manageAccountCallback;

  ManageAccountPage(
    this.appConfiguration, {
    Key key,
    @required this.manageAccountCallback,
  }) : super(key: key) {
    print("Constructing ManageAccountPage");
  }

  @override
  _ManageAccountPageState createState() => _ManageAccountPageState(appConfiguration, manageAccountCallback);
}

class _ManageAccountPageState extends LoadingSupportState<ManageAccountPage> {
  AppConfiguration appConfiguration;
  final ManageAccountCallback manageAccountCallback;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passPhraseController = TextEditingController(text: AppConfiguration.passPhrase);

  FocusNode actionButtonFocusNode;

  bool _showNewAccountOption = false;
  bool loading = false;
  int retryCount = 0;

  _ManageAccountPageState(this.appConfiguration, this.manageAccountCallback) {
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

  void showInfo(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
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
        AppConfiguration.passPhrase = passPhraseController.text;
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

  void _submit(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).requestFocus(actionButtonFocusNode);
      showError(localizations.heavyOperation);
      AppConfiguration.passPhrase = passPhraseController.text;
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
      encryptionKey: AppConfiguration.passPhrase,
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
      AccountEntity account = await accountService.setupMasterProxy(appConfiguration.account);
      appConfiguration = appConfiguration.copy(
        account: account,
      );
      manageAccountCallback(appConfiguration);
    }
  }

  void _createAccount(BuildContext context) async {
    print("Create Account");
    AccountEntity account = await accountService.createAccount(encryptionKey: AppConfiguration.passPhrase);
    UserEntity appUser = await UserStore.forUser(appConfiguration.firebaseUser).saveUser(
      appConfiguration.appUser.copy(accountId: account.accountId),
    );
    account = await accountService.setupMasterProxy(account);
    appConfiguration = appConfiguration.copy(
      account: account,
      appUser: appUser,
    );
    manageAccountCallback(appConfiguration);
  }
}
