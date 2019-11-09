import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:promo/authorizations_helper.dart';
import 'package:promo/banking/db/receiving_account_store.dart';
import 'package:promo/banking/deposit_helper.dart';
import 'package:promo/banking/model/receiving_account_entity.dart';
import 'package:promo/banking/payment_authorization_helper.dart';
import 'package:promo/banking/receiving_account_dialog.dart';
import 'package:promo/banking/widgets/receiving_account_card.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/home_page_navigation.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/enticement_factory.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/enticement_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_core/core.dart';
import 'package:uuid/uuid.dart';

import 'proxy_account_helper.dart';

final Uuid uuidFactory = Uuid();

enum PageMode { choose, manage }

class ReceivingAccountsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  final PageMode pageMode;
  final String currency;

  ReceivingAccountsPage(
    this.appConfiguration, {
    Key key,
    @required this.changeHomePage,
    @required this.pageMode,
    this.currency,
  }) : super(key: key) {
    print("Constructing ReceivingAccounts");
  }

  factory ReceivingAccountsPage.choose(
    AppConfiguration appConfiguration, {
    Key key,
    @required String currency,
  }) {
    return ReceivingAccountsPage(
      appConfiguration,
      changeHomePage: null,
      pageMode: PageMode.choose,
      currency: currency,
    );
  }

  factory ReceivingAccountsPage.manage(
    AppConfiguration appConfiguration, {
    @required ChangeHomePage changeHomePage,
    Key key,
  }) {
    return ReceivingAccountsPage(
      appConfiguration,
      changeHomePage: changeHomePage,
      pageMode: PageMode.manage,
    );
  }

  @override
  _ReceivingAccountsPageState createState() {
    return _ReceivingAccountsPageState(appConfiguration, changeHomePage, pageMode, currency);
  }
}

class _ReceivingAccountsPageState extends LoadingSupportState<ReceivingAccountsPage>
    with
        HomePageNavigation,
        EnticementHelper,
        DepositHelper,
        PaymentAuthorizationHelper,
        AccountHelper,
        AuthorizationsHelper {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;
  final String currency;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool loading = false;

  final PageMode pageMode;
  final ReceivingAccountStore _receivingAccountStore;
  Stream<List<ReceivingAccountEntity>> _receivingAccountsStream;

  _ReceivingAccountsPageState(this.appConfiguration, this.changeHomePage, this.pageMode, this.currency)
      : _receivingAccountStore = ReceivingAccountStore(appConfiguration);

  @override
  void initState() {
    super.initState();
    _receivingAccountsStream = _receivingAccountStore.subscribeForAccounts(
      proxyUniverse: appConfiguration.proxyUniverse,
      currency: currency,
    );
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  String _getTitle(ProxyLocalizations localizations) {
    String title = pageMode == PageMode.manage
        ? localizations.manageReceivingAccountsPageTitle
        : localizations.chooseReceivingAccountsPageTitle;
    return title + appConfiguration.proxyUniverseSuffix;
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getTitle(localizations)),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: streamBuilder(
          name: "Accounts Loading",
          stream: _receivingAccountsStream,
          builder: (context, accounts) => _accountsWidget(context, accounts),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createReceivingAccount(context),
        icon: Icon(Icons.add),
        label: Text(localizations.addAccountFabLabel),
      ),
      bottomNavigationBar: _bottomNavigationBar(context),
    );
  }

  Widget _bottomNavigationBar(BuildContext context) {
    if (changeHomePage == null || pageMode == PageMode.choose) {
      return null;
    }
    return navigationBar(
      context,
      HomePage.BankAccountsPage,
      changeHomePage: changeHomePage,
      busy: loading,
    );
  }

  Widget _accountsWidget(BuildContext context, List<ReceivingAccountEntity> accounts) {
    print("adding ${accounts.length} accounts");
    if (accounts.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          if (appConfiguration.proxyUniverse == ProxyUniverse.PRODUCTION)
            enticementCard(context, EnticementFactory.noReceivingAccounts, cancellable: false),
          if (appConfiguration.proxyUniverse == ProxyUniverse.TEST)
            enticementCard(context, EnticementFactory.addTestReceivingAccounts, cancellable: false),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: accounts.expand((account) {
        return [
          const SizedBox(height: 4.0),
          accountCard(context, account),
        ];
      }).toList(),
    );
  }

  Widget accountCard(BuildContext context, ReceivingAccountEntity account) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        child: ReceivingAccountCard(account: account),
        onTap: () {
          if (pageMode == PageMode.manage) {
            _edit(context, account);
          } else {
            Navigator.of(context).pop(account);
          }
        },
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => _archiveAccount(context, account),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, ReceivingAccountEntity receivingAccount) async {
    await Navigator.of(context).push(new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountDialog(appConfiguration, receivingAccount: receivingAccount),
        fullscreenDialog: true));
  }

  void _archiveAccount(BuildContext context, ReceivingAccountEntity receivingAccount) async {
    await _receivingAccountStore.archive(receivingAccount);
  }
}
