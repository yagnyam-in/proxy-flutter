import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/banking/receiving_account_card.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:uuid/uuid.dart';

final Uuid uuidFactory = Uuid();

class ReceivingAccounts extends StatefulWidget {
  final AppConfiguration appConfiguration;

  ReceivingAccounts({Key key, @required this.appConfiguration})
      : super(key: key) {
    print("Constructing ReceivingAccounts");
  }

  @override
  _ReceivingAccountsState createState() {
    return _ReceivingAccountsState();
  }
}

class _ReceivingAccountsState extends State<ReceivingAccounts> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ReceivingAccountRepo receivingAccountRepo =
      ServiceFactory.receivingAccountRepo();

  bool _isLoading = false;

  List<ReceivingAccountEntity> _accounts;

  @override
  void initState() {
    super.initState();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  void _refresh() {
    _refreshAccounts();
  }

  void _refreshAccounts() {
    receivingAccountRepo.fetchAccounts().then((accounts) {
      _setAccounts(accounts);
    }, onError: (e) {
      print(e);
      showToast(ProxyLocalizations.of(context).errorLoadingAccounts);
      _setAccounts([]);
    });
  }

  void _setAccounts(List<ReceivingAccountEntity> accounts) {
    print('setAccounts($accounts)');
    setState(() {
      _accounts = accounts;
      _isLoading = _accounts != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.receivingAccountsPageTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: localizations.refreshButtonHint,
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.add_box),
            tooltip: localizations.newReceivingAccountsButtonHint,
            onPressed: createNewAccount,
          ),
        ],
      ),
      body: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: ListView(
            children: rows(context),
          )),
    );
  }

  List<Widget> rows(BuildContext context) {
    List<Widget> rows = [];
    if (_accounts != null && _accounts.isNotEmpty) {
      print("adding ${_accounts.length} accounts");
      _accounts.forEach((account) {
        rows.addAll([
          const SizedBox(height: 8.0),
          accountCard(context, account),
        ]);
      });
    }
    return rows;
  }

  void createNewAccount() async {
    ReceivingAccountEntity receivingAccount = await Navigator.of(context).push(
        new MaterialPageRoute<ReceivingAccountEntity>(
            builder: (context) => ReceivingAccountDialog(),
            fullscreenDialog: true));
    if (receivingAccount != null) {
      receivingAccountRepo.save(receivingAccount);
    }
    _refresh();
  }

  Widget accountCard(BuildContext context, ReceivingAccountEntity account) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: GestureDetector(child: ReceivingAccountCard(account: account), onTap: () => _edit(context, account),),
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

  void _edit(
      BuildContext context, ReceivingAccountEntity receivingAccount) async {
    receivingAccount = await Navigator.of(context).push(
        new MaterialPageRoute<ReceivingAccountEntity>(
            builder: (context) =>
                ReceivingAccountDialog(receivingAccount: receivingAccount),
            fullscreenDialog: true));
    if (receivingAccount != null) {
      receivingAccountRepo.save(receivingAccount);
    }
    _refresh();
  }

  void _archiveAccount(
      BuildContext context, ReceivingAccountEntity receivingAccount) async {
    receivingAccount.active = false;
    await receivingAccountRepo.save(receivingAccount);
    _refreshAccounts();
  }
}
