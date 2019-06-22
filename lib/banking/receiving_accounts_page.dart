import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/banking/store/receiving_account_store.dart';
import 'package:proxy_flutter/banking/widgets/receiving_account_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:uuid/uuid.dart';

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
    return _ReceivingAccountsPageState(appConfiguration, changeHomePage, pageMode);
  }
}

class _ReceivingAccountsPageState extends LoadingSupportState<ReceivingAccountsPage> with HomePageNavigation {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  final PageMode pageMode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ReceivingAccountStore _receivingAccountStore;
  Stream<List<ReceivingAccountEntity>> _receivingAccountsStream;

  _ReceivingAccountsPageState(this.appConfiguration, this.changeHomePage, this.pageMode)
      : _receivingAccountStore = ReceivingAccountStore(appConfiguration);

  @override
  void initState() {
    super.initState();
    _receivingAccountsStream = _receivingAccountStore.subscribeForAccounts();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  bool _showAccount(ReceivingAccountEntity account) {
    if (pageMode == PageMode.manage) {
      return true;
    } else {
      return account.proxyUniverse == appConfiguration.proxyUniverse && account.currency == widget.currency;
    }
  }

  String _getTitle(ProxyLocalizations localizations) {
    return pageMode == PageMode.manage
        ? localizations.manageReceivingAccountsPageTitle
        : localizations.chooseReceivingAccountsPageTitle;
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getTitle(localizations)),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: StreamBuilder<List<ReceivingAccountEntity>>(
            stream: _receivingAccountsStream,
            initialData: [],
            builder: (BuildContext context, AsyncSnapshot<List<ReceivingAccountEntity>> snapshot) {
              return accountsWidget(context, snapshot);
            }),
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

  Widget accountsWidget(BuildContext context, AsyncSnapshot<List<ReceivingAccountEntity>> accounts) {
    List<Widget> rows = [
      actionBar(context),
    ];
    if (!accounts.hasData) {
      rows.add(
        Center(
          child: Text("Loading"),
        ),
      );
    } else if (accounts.data.isEmpty) {
      rows.add(
        Center(
          child: Text("No Accounts"),
        ),
      );
    } else {
      print("adding ${accounts.data.length} accounts");
      accounts.data.where(_showAccount).forEach((account) {
        rows.addAll([
          const SizedBox(height: 8.0),
          accountCard(context, account),
        ]);
      });
    }
    return ListView(
      children: rows,
    );
  }

  Widget actionBar(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        RaisedButton.icon(
          onPressed: () => createReceivingAccount(context),
          icon: Icon(Icons.add),
          label: Text(localizations.newReceivingAccountsButtonHint),
        ),
      ],
    );
  }

  void createReceivingAccount(BuildContext context) async {
    await Navigator.of(context).push(
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountDialog(
              appConfiguration,
              receivingAccount: ReceivingAccountEntity(
                proxyUniverse: appConfiguration.proxyUniverse,
                accountId: uuidFactory.v4(),
                currency: widget.currency,
              ),
            ),
        fullscreenDialog: true,
      ),
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
    await _receivingAccountStore.archiveAccount(receivingAccount);
  }
}
