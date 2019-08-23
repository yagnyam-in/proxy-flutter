import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/about_page.dart';
import 'package:proxy_flutter/db/account_store.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';
import 'package:share/share.dart';

import 'config/app_configuration.dart';
import 'model/account_entity.dart';
import 'widgets/widget_helper.dart';

class SettingsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  const SettingsPage(
    this.appConfiguration, {
    @required this.changeHomePage,
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
  final AccountStore _accountStore;
  Stream<AccountEntity> _accountStream;
  bool loading = false;

  SettingsPageState(this.appConfiguration, this.changeHomePage) : _accountStore = AccountStore();

  @override
  void initState() {
    super.initState();
    _accountStream = _accountStore.subscribeForAccount(appConfiguration.accountId);
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profilePageTitle + appConfiguration.proxyUniverseSuffix),
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
          stream: _accountStream,
          builder: (context, account) => _SettingsWidget(appConfiguration, account),
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
    print("Logout");
    AppConfigurationBloc.instance.signOut();
  }
}

class _SettingsWidget extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final AccountEntity accountEntity;

  const _SettingsWidget(this.appConfiguration, this.accountEntity, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SettingsWidgetState(appConfiguration, accountEntity);
  }
}

class _SettingsWidgetState extends State<_SettingsWidget> with WidgetHelper {
  final AppConfiguration appConfiguration;
  AccountEntity accountEntity;

  _SettingsWidgetState(this.appConfiguration, this.accountEntity);

  String _nullIfEmpty(String value) {
    return value == null || value.trim().isEmpty ? null : value;
  }

  String get displayName {
    return accountEntity.name ?? _nullIfEmpty(appConfiguration.firebaseUser.displayName);
  }

  String get phoneNumber {
    return accountEntity.phone ?? _nullIfEmpty(appConfiguration.firebaseUser.phoneNumber);
  }

  String get email {
    return accountEntity.email ?? _nullIfEmpty(appConfiguration.firebaseUser.email);
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
      const Divider(),
      _aboutWidget(context),
      // if (appConfiguration.proxyUniverse != ProxyUniverse.PRODUCTION) const Divider(),
      // if (appConfiguration.proxyUniverse != ProxyUniverse.PRODUCTION) _crashWidget(context),
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
      title: GestureDetector(
        onTap: () => _changePhoneNumber(context),
        child: Text(
          phoneNumber ?? localizations.authorizePhoneNumber,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: GestureDetector(
        onTap: () => _changePhoneNumber(context),
        child: Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            localizations.customerPhone,
          ),
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

  Widget _aboutWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => AboutPage(appConfiguration),
        ),
      ),
      child: ListTile(
        title: Text(
          localizations.about,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            localizations.aboutDescription,
          ),
        ),
        trailing: Icon(
          Icons.help,
        ),
      ),
    );
  }

  void _changeName(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String newName = await acceptNameDialog(
      context,
      pageTitle: localizations.changeNameTitle,
      fieldName: localizations.customerName,
      fieldInitialValue: displayName,
    );
    if (isNotEmpty(newName)) {
      AccountEntity updatedAccount = await AccountService.updatePreferences(
        appConfiguration,
        accountEntity,
        name: newName,
      );
      appConfiguration.account = updatedAccount;
      setState(() {
        accountEntity = updatedAccount;
      });
    }
  }

  void _changePhoneNumber(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String newPhoneNumber = await acceptPhoneNumberDialog(
      context,
      pageTitle: localizations.changePhoneNumberTitle,
      fieldName: localizations.customerPhone,
      fieldInitialValue: phoneNumber,
    );
    if (isNotEmpty(newPhoneNumber)) {
      AccountEntity updatedAccount = await AccountService.updatePreferences(
        appConfiguration,
        accountEntity,
        phone: newPhoneNumber,
      );
      appConfiguration.account = updatedAccount;
      setState(() {
        accountEntity = updatedAccount;
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
    String proxyUniverse = appConfiguration.proxyUniverse;
    if (proxyUniverse == ProxyUniverse.PRODUCTION) {
      proxyUniverse = ProxyUniverse.TEST;
    } else {
      proxyUniverse = ProxyUniverse.PRODUCTION;
    }
    AppConfigurationBloc.instance.appConfiguration = appConfiguration.copy(
      proxyUniverse: proxyUniverse,
    );
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
