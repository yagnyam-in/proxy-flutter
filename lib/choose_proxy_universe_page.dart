import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/app_configuration_bloc.dart';

import 'config/app_configuration.dart';

enum LoginMode { EmailLink, GoogleSignIn }

class ChooseProxyUniverse extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const ChooseProxyUniverse(this.appConfiguration, {Key key}) : super(key: key);

  @override
  _ChooseProxyUniverseState createState() {
    return _ChooseProxyUniverseState(appConfiguration);
  }
}

class _ChooseProxyUniverseState extends State<ChooseProxyUniverse> {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  _ChooseProxyUniverseState(this.appConfiguration);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: _chooseProxyUniverse(context),
      ),
    );
  }

  Widget _chooseProxyUniverse(BuildContext context) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _welcomeHeader(context),
            _proxyUniverseButtons(context),
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
          localizations.chooseProxyUniverseTitle,
          style: theme.textTheme.subhead.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(
          height: 5.0,
        ),
        Text(
          localizations.chooseProxyUniverseSubtitle,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _proxyUniverseButtons(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ThemeData theme = Theme.of(context);
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 60.0,
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              padding: EdgeInsets.fromLTRB(60, 12, 60, 12),
              shape: StadiumBorder(),
              child: Text(
                localizations.testButtonLabel,
              ),
              color: theme.buttonTheme.colorScheme.secondaryVariant,
              onPressed: () => _storProxyUniverse(ProxyUniverse.TEST),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: RaisedButton(
              padding: EdgeInsets.fromLTRB(60, 12, 60, 12),
              shape: StadiumBorder(),
              child: Text(
                localizations.productionButtonLabel,
              ),
              color: theme.buttonTheme.colorScheme.primary,
              onPressed: () => _storProxyUniverse(ProxyUniverse.PRODUCTION),
            ),
          ),
        ],
      ),
    );
  }

  void _storProxyUniverse(String proxyUniverse) async {
    await AppConfiguration.storeProxyUniverse(proxyUniverse);
    AppConfigurationBloc.instance.refresh(proxyUniverse: proxyUniverse);
  }
}
