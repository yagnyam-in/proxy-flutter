import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/user_store.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';
import 'package:share/share.dart';

import 'config/app_configuration.dart';
import 'widgets/widget_helper.dart';

class SettingsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;
  final AppConfigurationUpdater appConfigurationUpdater;

  const SettingsPage(
    this.appConfiguration, {
    @required this.changeHomePage,
    @required this.appConfigurationUpdater,
    Key key,
  }) : super(key: key);

  @override
  SettingsPageState createState() {
    return SettingsPageState(appConfiguration, changeHomePage);
  }
}

class SettingsPageState extends LoadingSupportState<SettingsPage> with HomePageNavigation {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;
  final UserStore _userStore;
  Stream<UserEntity> _userStream;
  bool loading = false;

  SettingsPageState(this.appConfiguration, this.changeHomePage)
      : _userStore = UserStore.forUser(appConfiguration.firebaseUser);

  @override
  void initState() {
    super.initState();
    _userStream = _userStore.subscribeForUser();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profilePageTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            tooltip: localizations.logout,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: streamBuilder(
          name: "Profile Loading",
          stream: _userStream,
          builder: (context, user) => _SettingsWidget(appConfiguration, user),
        ),
      ),
      bottomNavigationBar: navigationBar(
        context,
        HomePage.SettingsPage,
        changeHomePage: changeHomePage,
        busy: loading,
      ),
    );
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    AppConfiguration.storePassPhrase(null);
    widget.appConfigurationUpdater(appConfiguration.copy(
      firebaseUser: null,
      appUser: null,
      account: null,
      passPhrase: null,
    ));
  }
}

class _SettingsWidget extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final UserEntity userEntity;

  const _SettingsWidget(this.appConfiguration, this.userEntity, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsWidgetState(appConfiguration, userEntity);
  }
}

class _SettingsWidgetState extends State<_SettingsWidget> with WidgetHelper {
  final AppConfiguration appConfiguration;
  UserEntity userEntity;

  _SettingsWidgetState(this.appConfiguration, this.userEntity);

  String _nullIfEmpty(String value) {
    return value == null || value.trim().isEmpty ? null : value;
  }

  String get displayName {
    return userEntity.name ?? _nullIfEmpty(appConfiguration.firebaseUser.displayName);
  }

  String get phoneNumber {
    return userEntity.phone ?? _nullIfEmpty(appConfiguration.firebaseUser.phoneNumber);
  }

  String get email {
    return userEntity.email ?? _nullIfEmpty(appConfiguration.firebaseUser.email);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const SizedBox(height: 16.0),
      Icon(Icons.account_circle, size: 64.0),
      const SizedBox(height: 16.0),
      const Divider(),
      _profileWidget(context),
      const Divider(),
      _emailWidget(context),
      const Divider(),
      _phoneNumberWidget(context),
      const Divider(),
      _PassPhraseWidget(appConfiguration: appConfiguration),
      const Divider(),
      _proxyUniverseWidget(context),
      if (appConfiguration.proxyUniverse != ProxyUniverse.PRODUCTION) const Divider(),
      if (appConfiguration.proxyUniverse != ProxyUniverse.PRODUCTION) _crashWidget(context),
    ]);
  }

  Widget _profileWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: GestureDetector(
        onTap: () => _changeName(context),
        child: Text(
          displayName?.toUpperCase() ?? '🖊️️ ' + localizations.changeNameTitle,
        ),
      ),
      subtitle: GestureDetector(
        onTap: () => _changeName(context),
        child: Text(
          localizations.customerName,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _shareProfile(context),
        child: Icon(
          Icons.share,
        ),
      ),
    );
  }

  Widget _proxyUniverseWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        appConfiguration.proxyUniverse.toUpperCase(),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          localizations.proxyUniverse,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _changeProxyUniverse(context),
        child: Icon(
          Icons.swap_horiz,
        ),
      ),
    );
  }

  Widget _phoneNumberWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        phoneNumber ?? localizations.authorizePhoneNumber,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          localizations.customerPhone,
        ),
      ),
      trailing: Icon(
        Icons.phone_android,
      ),
    );
  }

  Widget _emailWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        email ?? localizations.authorizeEmail,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          localizations.customerEmail,
        ),
      ),
      trailing: Icon(
        Icons.email,
      ),
    );
  }

  Widget _crashWidget(BuildContext context) {
    return ListTile(
      title: Text(
        'Send a Crash',
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          'Only for testing',
        ),
      ),
      trailing: GestureDetector(
        onTap: () => Crashlytics.instance.crash(),
        child: Icon(
          Icons.error,
        ),
      ),
    );
  }

  void _changeName(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String newName = await acceptStringDialog(
      context,
      pageTitle: localizations.changeNameTitle,
      fieldName: localizations.customerName,
      fieldInitialValue: displayName,
    );
    if (isNotEmpty(newName)) {
      UserEntity newUser = userEntity.copy(name: newName);
      await UserStore.forUser(appConfiguration.firebaseUser).saveUser(newUser);
      appConfiguration.appUser = newUser;
      setState(() {
        userEntity = newUser;
      });
    }
  }

  Future<void> _shareProfile(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ProxyId proxyId = appConfiguration.masterProxyId;
    Uri link = Uri.parse(
        '${UrlConfig.PROXY_CENTRAL}/actions/add-proxy?id=${proxyId.id}&sha256Thumbprint=${proxyId.sha256Thumbprint}');
    var shortLink = await ServiceFactory.deepLinkService().createDeepLink(
      link,
      title: localizations.shareProfileTitle,
      description: localizations.shareProfileDescription,
    );
    var message =
        localizations.addMeToYourContacts(shortLink.toString()) + (isNotEmpty(displayName) ? ' - $displayName' : '');

    await Share.share(message);
  }

  void _changeProxyUniverse(BuildContext context) {
    setState(() {
      if (appConfiguration.proxyUniverse == ProxyUniverse.PRODUCTION) {
        appConfiguration.proxyUniverse = ProxyUniverse.TEST;
      } else {
        appConfiguration.proxyUniverse = ProxyUniverse.PRODUCTION;
      }
    });
  }
}

class _PassPhraseWidget extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const _PassPhraseWidget({Key key, this.appConfiguration}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PassPhraseWidgetState(appConfiguration);
  }
}

class _PassPhraseWidgetState extends State<_PassPhraseWidget> {
  final AppConfiguration appConfiguration;
  bool _showPassPhrase = false;

  _PassPhraseWidgetState(this.appConfiguration);

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return ListTile(
      title: Text(
        _showPassPhrase ? appConfiguration.passPhrase : '*' * appConfiguration.passPhrase.length,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          localizations.passPhrase,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => setState(() => _showPassPhrase = !_showPassPhrase),
        child: Icon(
          _showPassPhrase ? Icons.visibility_off : Icons.visibility,
        ),
      ),
    );
  }
}
