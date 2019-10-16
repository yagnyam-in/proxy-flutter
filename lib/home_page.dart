import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/authorize_email_page.dart';
import 'package:proxy_flutter/authorize_phone_number_page.dart';
import 'package:proxy_flutter/banking/accept_payment_page.dart';
import 'package:proxy_flutter/banking/db/deposit_store.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_store.dart';
import 'package:proxy_flutter/banking/db/payment_encashment_store.dart';
import 'package:proxy_flutter/banking/deposit_page.dart';
import 'package:proxy_flutter/banking/events_page.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_encashment_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_page.dart';
import 'package:proxy_flutter/banking/payment_encashment_page.dart';
import 'package:proxy_flutter/banking_home.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/contact_store.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:proxy_flutter/modify_contact_page.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:quiver/strings.dart';

import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage(this.appConfiguration, {Key key}) : super(key: key) {
    print("build home page with $appConfiguration");
  }

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends State<HomePage> {
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
    if (isNotEmpty(appConfiguration.email)) {
      ServiceFactory.emailAuthorizationService(appConfiguration)
          .authorizeEmailIfNotRequestedAlready(appConfiguration.email);
    }
    this.initDynamicLinks();
    // Doesn't work
    // WidgetsBinding.instance.addPostFrameCallback((_) => _triggerPhoneNumberVerification(context));
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
      _payment(link, link.queryParameters);
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
    String proxyUniverse = query['proxyUniverse'];
    String depositId = query['depositId'];
    DepositEntity deposit =
        await DepositStore(appConfiguration).fetchDeposit(proxyUniverse: proxyUniverse, depositId: depositId);
    if (deposit == null) {
      print("Couldn't find deposit for $query");
      return null;
    }
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => DepositPage(
          appConfiguration,
          proxyUniverse: proxyUniverse,
          depositId: depositId,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _payment(Uri link, Map<String, String> query) async {
    print("Launching dialog to accept payment $query");
    String proxyUniverse = query['proxyUniverse'];
    String paymentAuthorizationId = query['paymentAuthorizationId'];
    PaymentAuthorizationEntity paymentAuthorization =
        await PaymentAuthorizationStore(appConfiguration).fetchPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentAuthorization != null) {
      print("Launching Payment Authorization Page for $link");
      await Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => PaymentAuthorizationPage.forPaymentAuthorization(
            appConfiguration,
            paymentAuthorization,
          ),
          fullscreenDialog: true,
        ),
      );
      return;
    }
    PaymentEncashmentEntity paymentEncashment = await PaymentEncashmentStore(appConfiguration).fetchPaymentEncashment(
      proxyUniverse: proxyUniverse,
      paymentEncashmentId: null,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentEncashment != null) {
      print("Launching Payment Encashment Page for for $link");
      _launchPaymentEncashment(paymentEncashment);
      return;
    }
    print("Launching Payment Accept Page for $link");
    paymentEncashment = await Navigator.push(
      context,
      new MaterialPageRoute<PaymentEncashmentEntity>(
        builder: (context) => AcceptPaymentPage(
          appConfiguration,
          proxyUniverse: proxyUniverse,
          paymentAuthorizationId: paymentAuthorizationId,
          paymentLink: link.toString(),
        ),
        fullscreenDialog: true,
      ),
    );
    if (paymentEncashment != null) {
      _launchPaymentEncashment(paymentEncashment);
      return;
    }
  }

  Future<void> _launchPaymentEncashment(PaymentEncashmentEntity paymentEncashment) async {
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => PaymentEncashmentPage.forPaymentEncashment(
          appConfiguration,
          paymentEncashment,
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
