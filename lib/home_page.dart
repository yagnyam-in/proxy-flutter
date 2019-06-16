import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/accept_payment_page.dart';
import 'package:proxy_flutter/banking/banking_home.dart';
import 'package:proxy_flutter/banking/deposit_page.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/store/deposit_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/contact_store.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/setup_master_proxy_page.dart';

import 'modify_proxy_page.dart';
import 'widgets/basic_types.dart';

class HomePage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  HomePage({Key key, @required this.appConfiguration}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(appConfiguration);
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final AppConfiguration appConfiguration;

  bool _showWelcomePages = true;
  bool _masterProxySetup = false;

  _HomePageState(this.appConfiguration) {
    _showWelcomePages = appConfiguration.showWelcomePages;
    _masterProxySetup = appConfiguration.masterProxyId != null;
  }

  @override
  void initState() {
    super.initState();
    ServiceFactory.notificationService().start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("didChangeAppLifecycleState (ProxyAppState)");
      _handleDynamicLinks();
    }
  }

  Future<void> _handleDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.retrieveDynamicLink();
    Uri link = data?.link;
    if (link == null) return;
    print('link.path = ${link.path}');
    if (link.path == '/actions/add-proxy') {
      _addProxy(link.queryParameters);
    } else if (link.path == '/actions/deposit-status') {
      _depositStatus(link.queryParameters);
    } else if (link.path == '/actions/accept-payment') {
      _acceptPayment(link.queryParameters);
    } else {
      print('ignoring $link');
    }
  }

  Future<void> _addProxy(Map<String, String> query) async {
    print("Launching dialog to add proxy with $query");
    ProxyId proxyId = nullIfError(() => ProxyId(query['id'], query['sha256Thumbprint']));
    if (proxyId == null) {
      return null;
    }
    ContactEntity existingContact = await ContactStore(appConfiguration).fetchContact(proxyId);
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => ModifyProxyPage(appConfiguration, existingContact ?? ContactEntity(proxyId: proxyId)),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _depositStatus(Map<String, String> query) async {
    print("Launching dialog to show deposit status $query");
    String proxyUniverse = query['proxyUniverse'];
    String depositId = query['depositId'];
    DepositEntity deposit = await DepositStore(firebaseUser: appConfiguration.firebaseUser)
        .fetchDeposit(proxyUniverse: proxyUniverse, depositId: depositId);
    if (deposit == null) {
      print("Couldn't find deposit for $query");
      return null;
    }
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => DepositPage(
              appConfiguration: appConfiguration,
              proxyUniverse: proxyUniverse,
              depositId: depositId,
            ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _acceptPayment(Map<String, String> query) async {
    print("Launching dialog to accept payment $query");
    String proxyUniverse = query['proxyUniverse'];
    String paymentAuthorizationId = query['paymentAuthorizationId'];
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => AcceptPaymentPage(
              appConfiguration: appConfiguration,
              proxyUniverse: proxyUniverse,
              paymentAuthorizationId: paymentAuthorizationId,
            ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_masterProxySetup) {
      return SetupMasterProxyPage(
        appConfiguration: appConfiguration,
        setupMasterProxyCallback: setupMasterProxyCallback,
      );
    } else {
      return BankingHome(appConfiguration);
    }
  }

  void onWelcomeOver() {
    setState(() {
      _showWelcomePages = false;
      widget.appConfiguration.showWelcomePages = _showWelcomePages;
    });
  }

  void setupMasterProxyCallback(ProxyId proxyId) {
    print("setupMasterProxyCallback($proxyId)");
    setState(() {
      _masterProxySetup = true;
      widget.appConfiguration.masterProxyId = proxyId;
    });
    ServiceFactory.notificationService().refreshToken();
  }
}
