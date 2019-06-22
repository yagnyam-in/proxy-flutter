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
  final UserStore _userStore;
  Stream<UserEntity> _userStream;

  SettingsPageState(this.appConfiguration, this.changeHomePage) : _userStore = UserStore(appConfiguration);

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
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: streamBuilder(
            name: "Profile Loading",
            stream: _userStream,
            builder: (context, user) => _SettingsWidget(appConfiguration, user),
          ),
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
      _proxyUniverseWidget(context),
      const Divider(),
      _phoneNumberWidget(context),
      const Divider(),
      _emailWidget(context),
      const Divider(),
    ]);
  }

  Widget _profileWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 0.0),
      title: GestureDetector(
        onTap: () => _changeName(context),
        child: Text(
          displayName?.toUpperCase() ?? localizations.changeNameTitle,
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
      contentPadding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
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
      await UserStore(appConfiguration).saveUser(newUser);
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
