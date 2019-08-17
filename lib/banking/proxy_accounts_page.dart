import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/db/proxy_account_store.dart';
import 'package:proxy_flutter/banking/deposit_helper.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_helper.dart';
import 'package:proxy_flutter/banking/widgets/account_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/contacts_page.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/action_menu_item.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_flutter/services/enticement_service.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/enticement_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:uuid/uuid.dart';

import 'proxy_account_helper.dart';
import 'withdrawal_helper.dart';

final Uuid uuidFactory = Uuid();

class ProxyAccountsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  ProxyAccountsPage(
    this.appConfiguration, {
    Key key,
    @required this.changeHomePage,
  }) : super(key: key) {
    print("Constructing ProxyAccountsPage");
    assert(appConfiguration != null);
  }

  @override
  _ProxyAccountsPageState createState() {
    return _ProxyAccountsPageState(appConfiguration, changeHomePage);
  }
}

class _ProxyAccountsPageState extends LoadingSupportState<ProxyAccountsPage>
    with
        ProxyUtils,
        EnticementHelper,
        HomePageNavigation,
        DepositHelper,
        PaymentAuthorizationHelper,
        WithdrawalHelper,
        AccountHelper {
  static const String DEPOSIT = "deposit";
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<List<ProxyAccountEntity>> _proxyAccountsStream;
  Stream<List<Enticement>> _enticementsStream;
  bool loading = false;

  _ProxyAccountsPageState(this.appConfiguration, this.changeHomePage);

  @override
  void initState() {
    super.initState();
    _proxyAccountsStream = ProxyAccountStore(appConfiguration).subscribeForAccounts();
    _enticementsStream = EnticementService(appConfiguration).subscribeForFirstEnticement();
    ServiceFactory.bootService().warmUpBackends();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  List<ActionMenuItem> actions(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      ActionMenuItem(title: localizations.depositActionItemTitle, icon: Icons.file_download, action: DEPOSIT),
    ];
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.proxyAccountsPageTitle + appConfiguration.proxyUniverseSuffix),
        actions: <Widget>[
          PopupMenuButton<ActionMenuItem>(
            onSelected: (action) => _onAction(context, action),
            itemBuilder: (BuildContext context) {
              return actions(context).map((ActionMenuItem choice) {
                return PopupMenuItem<ActionMenuItem>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return streamBuilder(
                name: "Account Loading",
                stream: _proxyAccountsStream,
                builder: (context, accounts) => _accounts(context, accounts),
              );
            } else {
              return streamBuilder(
                name: "Enticement Loading",
                stream: _enticementsStream,
                loadingWidget: SizedBox.shrink(),
                builder: (context, enticements) => _enticements(context, enticements),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createAccountAndPay(context),
        icon: Icon(Icons.payment),
        label: Text(localizations.payFabLabel),
      ),
      bottomNavigationBar: navigationBar(
        context,
        HomePage.ProxyAccountsPage,
        busy: loading,
        changeHomePage: changeHomePage,
      ),
    );
  }

  Widget _accounts(
    BuildContext context,
    List<ProxyAccountEntity> accounts,
  ) {
    print("accounts : $accounts");
    if (accounts.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          enticementCard(context, EnticementFactory.noProxyAccounts, cancellable: false),
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

  Widget _enticements(
    BuildContext context,
    List<Enticement> enticements,
  ) {
    print("enticements : $enticements");
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: enticements.expand((enticement) {
        return [
          const SizedBox(height: 4.0),
          enticementCard(context, enticement),
        ];
      }).toList(),
    );
  }

  Widget accountCard(
    BuildContext context,
    ProxyAccountEntity account,
  ) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: AccountCard(account: account),
      actions: <Widget>[
        new IconSlideAction(
          caption: localizations.deposit,
          color: Colors.blue,
          icon: Icons.file_download,
          onTap: () => depositToAccount(context, account),
        ),
        new IconSlideAction(
          caption: 'Withdraw',
          color: Colors.indigo,
          icon: Icons.file_upload,
          onTap: () => withdrawFromAccount(context, account),
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.refreshButtonHint,
          color: Colors.orange,
          icon: Icons.refresh,
          onTap: () => refreshAccount(context, account),
        ),
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => archiveAccount(context, account),
        ),
      ],
    );
  }

  void _launchContacts(BuildContext context) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => ContactsPage.manage(appConfiguration: widget.appConfiguration),
      ),
    );
  }

  void _onAction(BuildContext context, ActionMenuItem action) {
    if (action.action == DEPOSIT) {
      createAccountAndDeposit(context);
    } else {
      print("Unknown action $action");
    }
  }
}
