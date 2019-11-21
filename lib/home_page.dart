import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:promo/authorize_email_page.dart';
import 'package:promo/authorize_phone_number_page.dart';
import 'package:promo/banking/db/deposit_store.dart';
import 'package:promo/banking/deposit_page.dart';
import 'package:promo/banking/events_page.dart';
import 'package:promo/banking/model/deposit_entity.dart';
import 'package:promo/banking_home.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/contact_store.dart';
import 'package:promo/model/contact_entity.dart';
import 'package:promo/modify_contact_page.dart';
import 'package:promo/services/service_factory.dart';
import 'package:proxy_core/core.dart';
import 'package:quiver/strings.dart';

import 'banking/payment_launcher.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage(this.appConfiguration, {Key key}) : super(key: key) {
    print("build home page with $appConfiguration");
  }

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends State<HomePage> with PaymentLauncher {
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final AppConfiguration appConfiguration;
  bool _triggeredPhoneVerification = false;

  _HomePageState(this.appConfiguration) {
    print("build home page state with $appConfiguration");
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().subscribeForAlerts();
    ServiceFactory.bootService().processPendingAlerts(appConfiguration);
    ServiceFactory.bootService().init(appConfiguration);
    this.initDynamicLinks();
    /*
    if (isNotEmpty(appConfiguration.email)) {
      ServiceFactory.emailAuthorizationService(appConfiguration).authorizeEmailIfNotRequestedAlready(appConfiguration.email);
    }
    // Doesn't work
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerPhoneNumberVerification(context));
    */
    /*
    FlutterNfcReader.read().then((response) {
      print("read: ${response.content}");
    });
    FlutterNfcReader.onTagDiscovered().listen((onData) {
      print("onTag: ${onData.id}");
      print("onTag: ${onData.content}");
    });
     */
  }

  void initDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      _handleDynamicLinks(deepLink);
    }
    FirebaseDynamicLinks.instance.onLink(onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;
      if (deepLink != null) {
        _handleDynamicLinks(deepLink);
      }
    }, onError: (OnLinkErrorException e) async {
      print('initDynamicLinks: ${e.message}');
    });
  }

  Future<void> _handleDynamicLinks(Uri link) async {
    if (link == null) return;
    print('link.path = ${link.path}');
    if (link.path == '/actions/add-me') {
      _addContact(link, link.queryParameters);
    } else if (link.path == '/actions/deposit-status') {
      _depositStatus(link, link.queryParameters);
    } else if (link.path == '/actions/accept-payment') {
      launchPayment(context, link);
    } else if (link.path == '/actions/verify-email') {
      _verifyEmail(link, link.queryParameters);
    } else {
      print('ignoring $link');
    }
  }

  Future<void> _addContact(Uri link, Map<String, String> query) async {
    print("Launching dialog to add proxy with $query");
    if (isEmpty(query[SettingsPage.PROXY_ID_PARAM]) || isEmpty(query[SettingsPage.PROXY_SHA256_PARAM])) {
      print("Ignoring request as mandatory parameters aren't set");
      return;
    }
    ProxyId proxyId = ProxyId(query[SettingsPage.PROXY_ID_PARAM], query[SettingsPage.PROXY_SHA256_PARAM]);
    if (!proxyId.isValid()) {
      print("Ignoring request as proxy id $proxyId isn't valid");
    }
    List<ContactEntity> existingContacts = await ContactStore(appConfiguration).fetchContactByProxyId(proxyId);
    if (existingContacts.isEmpty) {
      existingContacts.add(
        ContactEntity(
          id: uuidFactory.v4(),
          proxyId: proxyId,
          // Don't take anything else like name, phone or email. As someone can mislead with links.
        ),
      );
    }
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => ModifyContactPage(appConfiguration, existingContacts.first),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _depositStatus(Uri link, Map<String, String> query) async {
    print("Launching dialog to show deposit status $query");
    String bankId = query['bankId'];
    String depositId = query['depositId'];
    DepositEntity deposit = await DepositStore(appConfiguration).fetch(bankId: bankId, depositId: depositId);
    if (deposit == null) {
      print("Couldn't find deposit for $query");
      return null;
    }
    print("Launching $deposit");
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => DepositPage(
          appConfiguration,
          deposit: deposit,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _verifyEmail(Uri link, Map<String, String> query) async {
    print("Verify email using $link");
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => AuthorizeEmailPage.forId(
          appConfiguration,
          authorizationId: query['authorizationId'],
          secret: query['secret'],
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Returning Banking Home Page with $appConfiguration");
    return BankingHome(
      appConfiguration,
      key: ValueKey(appConfiguration),
    );
  }

  void _triggerPhoneNumberVerification(BuildContext context) async {
    if (_triggeredPhoneVerification) {
      return;
    }
    _triggeredPhoneVerification = true;
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => AuthorizePhoneNumberPage.forPhoneNumber(appConfiguration, appConfiguration.phoneNumber),
      ),
    );
  }
}
