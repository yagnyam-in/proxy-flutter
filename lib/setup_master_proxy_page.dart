import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/native_proxy_key_store_impl.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:tuple/tuple.dart';

typedef SetupMasterProxyCallback = void Function(ProxyId proxyId);

class SetupMasterProxyPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final SetupMasterProxyCallback setupMasterProxyCallback;

  SetupMasterProxyPage(
    this.appConfiguration, {
    Key key,
    @required this.setupMasterProxyCallback,
  }) : super(key: key) {
    print("Constructing SetupMasterProxyPage");
  }

  @override
  _SetupMasterProxyPageState createState() => _SetupMasterProxyPageState();
}

class _SetupMasterProxyPageState extends State<SetupMasterProxyPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final NativeProxyKeyStoreImpl proxyKeyStore = NativeProxyKeyStoreImpl();
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final ProxyFactory proxyFactory = ProxyFactory();

  bool loading = false;

  Future<ProxyKey> createProxyKey(String proxyId) {
    print("createProxyKey");
    return proxyKeyStore.createProxyKey(
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
    return proxyKeyStore.createProxyRequest(
      proxyKey: proxyKey,
      signatureAlgorithm: proxyVersion.certificateSignatureAlgorithm,
      revocationPassPhrase: revocationPassPhrase,
    );
  }

  Future<Proxy> createProxy(ProxyRequest proxyRequest) {
    Future<Proxy> proxy = proxyFactory.createProxy(proxyRequest);
    return proxy;
  }

  Future<Tuple2<ProxyKey, Proxy>> saveProxy(
    ProxyKey proxyKey,
    Proxy proxy,
  ) async {
    await proxyKeyStore.saveProxy(proxyKey: proxyKey, proxy: proxy);
    DB.instance().transaction((t) async {
      await ProxyRepo.insertInTransaction(t, proxy);
      await ProxyKeyRepo.insertInTransaction(t, proxyKey);
    });
    return Tuple2(proxyKey, proxy);
  }

  Future<Tuple2<ProxyKey, Proxy>> setup(
    String proxyId,
    String revocationPassPhrase,
  ) async {
    ProxyKey proxyKey = await createProxyKey(proxyId);
    ProxyRequest proxyRequest = await createProxyRequest(proxyKey, revocationPassPhrase);
    Proxy proxy = await createProxy(proxyRequest);
    return saveProxy(proxyKey.copyWith(id: proxy.id), proxy);
  }

  void setupMasterProxy(
    BuildContext context,
    String proxyId,
    String revocationPassPhrase,
  ) async {
    setState(() {
      loading = true;
    });
    setup(proxyId, revocationPassPhrase).then((Tuple2<ProxyKey, Proxy> r) {
      setState(() {
        print("Success!! ${r.item1} => ${r.item2.isValid()}");
        loading = false;
      });
      widget.setupMasterProxyCallback(r.item1.id);
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).setupMasterProxyTitle),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: SetupProxyForm(
            setupProxyCallback: (String proxyId, String revocationPassPhrase) =>
                setupMasterProxy(context, proxyId, revocationPassPhrase),
            appConfiguration: widget.appConfiguration,
          ),
        ),
      ),
    );
  }
}

typedef SetupProxyCallback = void Function(String proxyId, String revocationPassPhrase);

class SetupProxyForm extends StatefulWidget {
  final SetupProxyCallback setupProxyCallback;
  final AppConfiguration appConfiguration;

  SetupProxyForm({@required this.setupProxyCallback, @required this.appConfiguration, Key key}) : super(key: key);

  @override
  _SetupProxyFormState createState() => _SetupProxyFormState(appConfiguration.firebaseUser.uid);
}

class _SetupProxyFormState extends State<SetupProxyForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode revocationPassPhraseFocusNode = FocusNode();
  final FocusNode tosFocusNode = FocusNode();
  final TextEditingController proxyIdController; // = ;
  final TextEditingController revocationPassPhraseController;

  _SetupProxyFormState(String suggestedProxyId)
      : this.proxyIdController = TextEditingController(text: suggestedProxyId),
        this.revocationPassPhraseController = TextEditingController(text: RandomUtils.randomSecret(16));

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const SizedBox(height: 8.0),
          Text(
            localizations.masterProxyDescription,
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            enabled: false,
            controller: proxyIdController,
            decoration: InputDecoration(
              labelText: localizations.proxyId,
              // hintText: localizations.proxyIdHint,
              helperText: localizations.proxyIdHint,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _proxyIdValidator(localizations, value),
            onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(revocationPassPhraseFocusNode),
          ),
          const SizedBox(height: 8.0),
          Text(
            localizations.revocationPassPhraseDescription,
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: revocationPassPhraseController,
            focusNode: revocationPassPhraseFocusNode,
            decoration: InputDecoration(
              labelText: localizations.revocationPassPhrase,
              // hintText: localizations.revocationPassPhraseHint,
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
                onPressed: _submit,
                child: Text(localizations.setupProxyButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      print("Requesting proxy with ${proxyIdController.text}/${revocationPassPhraseController.text}");
      widget.setupProxyCallback(proxyIdController.text, revocationPassPhraseController.text);
    } else {
      print("Validation failure");
    }
  }

  bool _isValidProxyId(String proxyId) {
    return proxyId != null && proxyId.trim().length >= 8 && proxyId.trim().length <= 36 && ProxyId.isValidId(proxyId);
  }

  bool _isValidPassphrase(String passphrase) {
    return passphrase != null && passphrase.length >= 8 && passphrase.length <= 64;
  }

  String _proxyIdValidator(ProxyLocalizations localizations, String proxyId) {
    if (proxyId.isEmpty) {
      return localizations.fieldIsMandatory(localizations.proxyId);
    } else if (!_isValidProxyId(proxyId)) {
      return localizations.invalidProxyId;
    }
    return null;
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
