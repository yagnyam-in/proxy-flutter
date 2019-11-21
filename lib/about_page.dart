import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/widgets/async_helper.dart';

class AboutPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const AboutPage(this.appConfiguration, {Key key}) : super(key: key);

  @override
  AboutPageState createState() {
    return AboutPageState(appConfiguration);
  }
}

class AboutPageState extends State<AboutPage> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<PackageInfo> _packageInfoFuture;

  AboutPageState(this.appConfiguration);

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.about),
      ),
      body: ListView(children: [
        const SizedBox(height: 16.0),
        Icon(Icons.security, size: 64.0),
        const SizedBox(height: 16.0),
        const Divider(),
        _appVersion(context),
        const Divider(),
        _masterProxyId(context),
        const Divider(),
        _account(context),
        const Divider(),
        _device(context),
        const Divider(),
      ]),
    );
  }

  Widget _appVersion(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        localizations.appVersion,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: futureBuilder(
          future: _packageInfoFuture,
          errorMessage: localizations.unknown,
          emptyMessage: localizations.unknown,
          builder: (context, packageInfo) {
            return Text(
              packageInfo.version,
            );
          },
        ),
      ),
      trailing: Icon(
        Icons.help,
      ),
    );
  }

  Widget _masterProxyId(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        localizations.masterProxyId,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          appConfiguration.masterProxyId.id,
        ),
      ),
      trailing: Icon(
        Icons.security,
      ),
    );
  }

  Widget _account(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        localizations.accountId,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          appConfiguration.accountId,
        ),
      ),
      trailing: Icon(
        Icons.account_circle,
      ),
    );
  }

  Widget _device(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      title: Text(
        localizations.deviceId,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          appConfiguration.deviceId,
        ),
      ),
      trailing: Icon(
        Icons.perm_device_information,
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

  void showMessage(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
