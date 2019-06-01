import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:quiver/strings.dart';

import 'config/app_configuration.dart';
import 'widgets/widget_helper.dart';
import 'package:share/share.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class ProfilePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  const ProfilePage({Key key, @required this.appConfiguration}) : super(key: key);

  @override
  ProfilePageState createState() {
    return ProfilePageState(appConfiguration: appConfiguration);
  }
}

class ProfilePageState extends LoadingSupportState<ProfilePage> with WidgetHelper {
  final AppConfiguration appConfiguration;

  ProfilePageState({@required this.appConfiguration});

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profilePageTitle),
        actions: [
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: new Text(
              localizations.okButtonLabel,
              style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: body(context, localizations),
        ),
      ),
    );
  }

  Widget body(BuildContext context, ProxyLocalizations localizations) {
    ThemeData themeData = Theme.of(context);

    List<Widget> rows = [
      const SizedBox(height: 16.0),
      Icon(Icons.account_circle, size: 64.0),
      const SizedBox(height: 24.0),
      Center(
        child: GestureDetector(
          onTap: () => _changeName(context, localizations),
          child: Text(
            appConfiguration.customerName ?? localizations.changeNameTitle,
            style: themeData.textTheme.title,
          ),
        ),
      ),
    ];
    rows.add(const SizedBox(height: 24.0));
    rows.add(ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: [
        RaisedButton.icon(
          onPressed: () => invoke(() => _shareProfile(context, localizations)),
          icon: Icon(Icons.share),
          label: Text(localizations.shareProfile),
        ),
      ],
    ));
    return ListView(children: rows);
  }

  void _changeName(
    BuildContext context,
    ProxyLocalizations localizations,
  ) async {
    String newName = await acceptStringDialog(
      context,
      pageTitle: localizations.changeNameTitle,
      fieldName: localizations.customerName,
      fieldInitialValue: appConfiguration.customerName,
    );
    if (isNotEmpty(newName)) {
      appConfiguration.customerName = newName;
    }
  }

  Future<void> _shareProfile(
    BuildContext context,
    ProxyLocalizations localizations,
  ) async {
    ProxyId proxyId = appConfiguration.masterProxyId;
    Uri link = Uri.parse('${UrlConfig.PROXY_CENTRAL}/actions/add-proxy?id=${proxyId.id}&sha256Thumbprint=${proxyId.sha256Thumbprint}');
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: UrlConfig.DYNAMIC_LINK_PREFIX,
      link: link,
      androidParameters: AndroidParameters(
        packageName: 'in.yagnyam.proxy',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Proxy Id',
        description: 'Add Proxy Id to contacts',
      ),
    );
    var shortLink = await parameters.buildShortLink();
    var message = localizations.addMeToYourContacts(shortLink.shortUrl.toString()) +
        (isNotEmpty(appConfiguration.customerName) ? ' - ${appConfiguration.customerName}' : '');

    await Share.share(message);
  }
}
