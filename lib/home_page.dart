import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/authorize_email_page.dart';
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
import 'package:proxy_flutter/widgets/async_helper.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage(this.appConfiguration, {Key key}) : super(key: key) {
    print("build home page with $appConfiguration");
  }

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends LoadingSupportState<HomePage> {
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final AppConfiguration appConfiguration;
  bool loading = false;

  _HomePageState(this.appConfiguration) {
    print("build home page state with $appConfiguration");
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.bootService().subscribeForAlerts();
    ServiceFactory.bootService().processPendingAlerts(appConfiguration);
    this.initDynamicLinks();
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
      invoke(() => _verifyEmail(link, link.queryParameters), name: 'Verify Email');
    } else {
      print('ignoring $link');
    }
  }

  Future<void> _addContact(Uri link, Map<String, String> query) async {
    print("Launching dialog to add proxy with $query");
    List<ContactEntity> existingContacts = await ContactStore(appConfiguration).fetchContacts(
      phoneNumber: query['phoneNumber'],
      email: query['email'],
    );
    if (existingContacts.isEmpty) {
      existingContacts.add(
        ContactEntity(
          id: uuidFactory.v4(),
          phoneNumber: query['phoneNumber'],
          email: query['email'],
          name: query['name'],
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
      return;
    }
    print("Launching Payment Accept Page for $link");
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => AcceptPaymentPage(
          appConfiguration,
          proxyUniverse: proxyUniverse,
          paymentAuthorizationId: paymentAuthorizationId,
          paymentLink: link.toString(),
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
}
