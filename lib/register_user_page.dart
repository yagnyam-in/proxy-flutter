import 'dart:async';

import 'package:flutter/material.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/db/proxy_store.dart';
import 'package:proxy_flutter/db/user_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/native_proxy_key_store_impl.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';

typedef RegisterUserCallback = void Function(UserEntity user);

class RegisterUserPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final RegisterUserCallback registerUserCallback;

  RegisterUserPage(
    this.appConfiguration, {
    Key key,
    @required this.registerUserCallback,
  }) : super(key: key) {
    print("Constructing RegisterUserPage");
  }

  @override
  _RegisterUserPageState createState() => _RegisterUserPageState(appConfiguration);
}

class _RegisterUserPageState extends LoadingSupportState<RegisterUserPage> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final NativeProxyKeyFactoryImpl _proxyKeyFactoryImpl = NativeProxyKeyFactoryImpl();
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final ProxyFactory proxyFactory = ProxyFactory();
  final String proxyId = RandomUtils.randomProxyId();
  final TextEditingController passPhraseController = TextEditingController(text: RandomUtils.randomSecret(16));

  bool loading = false;

  _RegisterUserPageState(this.appConfiguration);

  Future<ProxyKey> createProxyKey(String proxyId) {
    print("createProxyKey");
    return _proxyKeyFactoryImpl.createProxyKey(
      id: proxyId,
      keyGenerationAlgorithm: proxyVersion.keyGenerationAlgorithm,
      keySize: proxyVersion.keySize,
    );
  }

  Future<ProxyRequest> createProxyRequest(
    ProxyKey proxyKey,
    String revocationPassPhrase,
  ) {
    print("createProxyRequest");
    return _proxyKeyFactoryImpl.createProxyRequest(
      proxyKey: proxyKey,
      signatureAlgorithm: proxyVersion.certificateSignatureAlgorithm,
      revocationPassPhrase: revocationPassPhrase,
    );
  }

  Future<Proxy> createProxy(ProxyRequest proxyRequest) {
    Future<Proxy> proxy = proxyFactory.createProxy(proxyRequest);
    return proxy;
  }

  Future<UserEntity> _setup(
    String proxyId,
    String revocationPassPhrase,
  ) async {
    ProxyKey proxyKey = await createProxyKey(proxyId);
    ProxyRequest proxyRequest = await createProxyRequest(proxyKey, revocationPassPhrase);
    Proxy proxy = await createProxy(proxyRequest);
    await _proxyKeyFactoryImpl.saveProxy(proxyKey: proxyKey, proxy: proxy);
    await ProxyKeyStore(appConfiguration).insertProxyKey(proxyKey);
    await ProxyStore(appConfiguration).insertProxy(proxy);
    UserEntity userEntity = await UserStore(appConfiguration).saveUser(
      UserEntity(
        masterProxyId: proxy.id,
      ),
    );
    return userEntity;
  }

  void setupMasterProxy(
    BuildContext context,
    String revocationPassPhrase,
  ) async {
    print("Requesting proxy for $proxyId");
    setState(() {
      loading = true;
    });
    _setup(proxyId, revocationPassPhrase).then((r) {
      setState(() {
        print("Success!! $r");
        loading = false;
      });
      widget.registerUserCallback(r);
    }).catchError((e) {
      setState(() {
        print("Failure!! $e");
        loading = false;
      });
      showError(ProxyLocalizations.of(context).failedProxyCreation);
    });
  }

  void showError(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().start();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.registerUserTitle),
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
                  localizations.registerUserDescription,
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: passPhraseController,
                  decoration: InputDecoration(
                    labelText: localizations.revocationPassPhrase,
                    helperText: localizations.revocationPassPhraseHint,
                  ),
                  validator: (value) => _passphraseIdValidator(localizations, value),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    // const Spacer(),
                    RaisedButton(
                      onPressed: () => _submit(context),
                      child: Text(localizations.setupProxyButtonLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState.validate()) {
      setupMasterProxy(context, passPhraseController.text);
    } else {
      print("Validation failure");
    }
  }

  bool _isValidPassphrase(String passphrase) {
    return passphrase != null && passphrase.length >= 16 && passphrase.length <= 64;
  }

  String _passphraseIdValidator(ProxyLocalizations localizations, String passphrase) {
    if (passphrase.isEmpty) {
      return localizations.fieldIsMandatory(localizations.revocationPassPhrase);
    } else if (!_isValidPassphrase(passphrase)) {
      return localizations.revocationPassPhrase;
    }
    return null;
  }
}
