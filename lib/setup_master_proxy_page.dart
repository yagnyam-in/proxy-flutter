import 'package:flutter/material.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/app_state_container.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/app_state.dart';
import 'package:proxy_flutter/services/proxy_key_store_impl.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:tuple/tuple.dart';

class SetupMasterProxyPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  SetupMasterProxyPage({Key key, @required this.appConfiguration}) : super(key: key) {
    print("Constructing SetupMasterProxyPage");
  }

  @override
  _SetupMasterProxyPageState createState() => _SetupMasterProxyPageState();
}

class _SetupMasterProxyPageState extends State<SetupMasterProxyPage> {

  AppState appState;
  final ProxyKeyStoreImpl proxyKeyStore = ProxyKeyStoreImpl();
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final ProxyFactory proxyFactory = ProxyFactory();

  Future<ProxyKey> createProxyKey(String proxyId) {
    print("createProxyKey");
    return proxyKeyStore.createProxyKey(
      id: proxyId,
      keyGenerationAlgorithm: proxyVersion.keyGenerationAlgorithm,
      keySize: proxyVersion.keySize,
    );
  }

  Future<ProxyRequest> createProxyRequest(ProxyKey proxyKey, String revocationPassPhrase) {
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

  Future<Tuple2<ProxyKey, Proxy>> setup(String proxyId, String revocationPassPhrase) async {
    ProxyKey proxyKey = await createProxyKey(proxyId);
    ProxyRequest proxyRequest = await createProxyRequest(proxyKey, revocationPassPhrase);
    Proxy proxy = await createProxy(proxyRequest);
    return Tuple2(proxyKey, proxy);
  }

  void setupMasterProxy(String proxyId, String revocationPassPhrase) {
    setState(() {
      appState.isLoading = true;
    });
    setup(proxyId, revocationPassPhrase).then((Tuple2<ProxyKey, Proxy> r) {
      setState(() {
        print("Success!! ${r.item1} => ${r.item2.isValid()}");
        appState.isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        print("Failure!! $e: ${StackTrace.current}");
        appState.isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    appState = AppStateContainer.of(context).state;
    double childOpacity = appState.isLoading ? 0.5 : 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).setupMasterProxyTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Stack(
            children: <Widget>[
              Opacity(
                opacity: 1 - childOpacity,
                child: LoadingWidget(),
              ),
              Opacity(
                opacity: childOpacity,
                child: SetupProxyForm(
                  setupProxyCallback: setupMasterProxy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef SetupProxyCallback = void Function(String proxyId, String revocationPassPhrase);

class SetupProxyForm extends StatefulWidget {
  final SetupProxyCallback setupProxyCallback;

  SetupProxyForm({@required this.setupProxyCallback, Key key}) : super(key: key);

  @override
  _SetupProxyFormState createState() => _SetupProxyFormState();
}

class _SetupProxyFormState extends State<SetupProxyForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController proxyIdController = TextEditingController();
  final TextEditingController revocationPassPhraseController = TextEditingController();

  bool _agreedToTOS = true;

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16.0),
          Text(
            localizations.masterProxyDescription,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: proxyIdController,
            decoration: InputDecoration(
              labelText: localizations.proxyId,
              hintText: localizations.proxyIdHint,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => _proxyIdValidator(localizations, value),
          ),
          const SizedBox(height: 32.0),
          Text(
            localizations.revocationPassPhraseDescription,
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: revocationPassPhraseController,
            decoration: InputDecoration(
              labelText: localizations.revocationPassPhrase,
              hintText: localizations.revocationPassPhraseHint,
            ),
            validator: (value) => _passphraseIdValidator(localizations, value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: <Widget>[
                Checkbox(
                  value: _agreedToTOS,
                  onChanged: _setAgreedToTOS,
                ),
                GestureDetector(
                  onTap: () => _setAgreedToTOS(!_agreedToTOS),
                  child: Text(
                    localizations.agreeTermsAndConditions,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // const Spacer(),
              RaisedButton(
                onPressed: _submittable() ? _submit : null,
                child: Text(localizations.setupProxyButtonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _submittable() {
    return _agreedToTOS;
  }

  void _submit() {
    if (_formKey.currentState.validate()) {
      print("Requesting proxy with ${proxyIdController.text}/${revocationPassPhraseController.text}");
      widget.setupProxyCallback(proxyIdController.text, revocationPassPhraseController.text);
    } else {
      print("Validation failure");
    }
  }

  void _setAgreedToTOS(bool newValue) {
    setState(() {
      _agreedToTOS = newValue;
    });
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
