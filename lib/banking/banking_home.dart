import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/account_card.dart';
import 'package:proxy_flutter/banking/enticement_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/banking_service.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

final Uuid uuidFactory = Uuid();

class BankingHome extends StatefulWidget {
  final AppConfiguration appConfiguration;

  BankingHome({Key key, @required this.appConfiguration}) : super(key: key) {
    print("Constructing BankingHome");
  }

  @override
  _BankingHomeState createState() {
    return _BankingHomeState();
  }
}

class _BankingHomeState extends State<BankingHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProxyKeyRepo proxyKeyRepo = ServiceFactory.proxyKeyRepo();
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final ProxyAccountRepo proxyAccountRepo = ServiceFactory.proxyAccountRepo();
  final BankingService bankingService = ServiceFactory.bankingService();

  bool _isLoading = false;

  List<ProxyAccountEntity> _accounts;
  EnticementEntity _enticement;

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
    _refreshAccounts();
    _refreshEnticements();
  }

  void _refreshAccounts() {
    proxyAccountRepo.fetchAccounts().then((accounts) {
      _setAccounts(accounts);
    }, onError: (e) {
      print(e);
      showToast(ProxyLocalizations.of(context).errorLoadingAccounts);
      _setAccounts([]);
    });
  }

  void _refreshEnticements() {
    EnticementFactory.instance().getEnticement(context).then((enticement) {
      _setEnticement(enticement);
    }, onError: (e) {
      print(e);
      _setEnticement(null);
    });
  }

  void _setEnticement(EnticementEntity enticement) {
    print('setEnticement($enticement)');
    setState(() {
      _enticement = enticement;
    });
  }

  void _setAccounts(List<ProxyAccountEntity> accounts) {
    print('setAccounts($accounts)');
    setState(() {
      _accounts = accounts;
      _isLoading = _accounts != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).bankingTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.playlist_add),
            tooltip: 'New Wallet',
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
    List<Widget> rows = [
      actionBar(context),
    ];
    if (_accounts != null && _accounts.isNotEmpty) {
      print("adding ${_accounts.length} accounts");
      _accounts.forEach((account) {
        rows.addAll([
          const SizedBox(height: 8.0),
          accountCard(context, account),
        ]);
      });
    }
    if (_enticement != null) {
      rows.addAll([
        const SizedBox(height: 8.0),
        enticementCard(context, _enticement),
      ]);
    }
    return rows;
  }

  Widget actionBar(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        RaisedButton.icon(onPressed: deposit, icon: Icon(Icons.file_download), label: Text(localizations.deposit)),
        RaisedButton.icon(onPressed: payment, icon: Icon(Icons.file_upload), label: Text(localizations.payment)),
      ],
    );
  }

  void deposit() async {
    if (_accounts.isEmpty) {
      return createNewAccount();
    }
  }

  void payment() async {
    if (_accounts.isEmpty) {
      return createNewAccount();
    }
  }

  void createNewAccount() async {
    String currency = await showDialog(
      context: context,
      builder: (context) => currencyDialog(context),
    );
    if (Currency.isValidCurrency(currency)) {
      showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
      ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(widget.appConfiguration.masterProxyId);
      await bankingService.createProxyWallet(proxyKey, currency);
      _refreshAccounts();
      _refreshEnticements();
    }
  }

  Widget currencyDialog(BuildContext context) {
    return SimpleDialog(
      title: Text('Choose Currency'),
      children: <Widget>[
        SimpleDialogOption(
          child: new Text(Currency.INR),
          onPressed: () {
            Navigator.pop(context, Currency.INR);
          },
        ),
        SimpleDialogOption(
          child: new Text(Currency.EUR),
          onPressed: () {
            Navigator.pop(context, Currency.EUR);
          },
        ),
      ],
    );
  }

  Widget accountCard(BuildContext context, ProxyAccountEntity account) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: AccountCard(account: account),
      actions: <Widget>[
        new IconSlideAction(
          caption: localizations.deposit,
          color: Colors.blue,
          icon: Icons.file_download,
          onTap: () => showToast('Deposit'),
        ),
        new IconSlideAction(
          caption: 'Withdraw',
          color: Colors.indigo,
          icon: Icons.file_upload,
          onTap: () => showToast('Widthdraw'),
        ),
      ],
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

  void _deposit(BuildContext context, ProxyAccountEntity proxyAccount) {

  }

  void _archiveAccount(BuildContext context, ProxyAccountEntity proxyAccount) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (proxyAccount.balance.value != 0) {
      showToast(localizations.canNotDeleteActiveAccount);
      return;
    }
    proxyAccountRepo.deleteAccount(proxyAccount);
    _refreshAccounts();
  }

  Widget enticementCard(BuildContext context, EnticementEntity enticement) {
    return Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: EnticementCard(enticement: enticement),
      secondaryActions: <Widget>[
        new IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () {
              EnticementFactory.instance().dismissEnticement(context, enticement);
              _refreshEnticements();
            }),
      ],
    );
  }
}
