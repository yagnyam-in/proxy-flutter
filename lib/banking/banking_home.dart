import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/accept_amount_dialog.dart';
import 'package:proxy_flutter/banking/account_card.dart';
import 'package:proxy_flutter/banking/enticement_card.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/banking/receiving_accounts.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_flutter/services/banking_service.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_messages/banking.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final ReceivingAccountRepo receivingAccountRepo = ServiceFactory.receivingAccountRepo();

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
    _refresh();
  }

  void _refresh() {
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
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.bankingTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: localizations.refreshButtonHint,
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.account_balance),
            tooltip: localizations.receivingAccountsButtonHint,
            onPressed: _manageReceivingAccounts,
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
    Tuple2<String, Amount> result = await Navigator.of(context)
        .push(new MaterialPageRoute<Tuple2<String, Amount>>(builder: (context) => AcceptAmountDialog(), fullscreenDialog: true));
    if (result != null) {
      showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
      ProxyAccountEntity proxyAccount =
          await bankingService.createProxyWallet(ownerProxyId: widget.appConfiguration.masterProxyId, proxyUniverse: result.item1, currency: result.item2.currency,);
      String depositLink = await bankingService.depositLink(proxyAccount, result.item2);
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
      _refreshAccounts();
      _refreshEnticements();
    }
  }

  void payment() async {
    if (_accounts.isEmpty) {
      return createNewAccount();
    }
  }

  void createNewAccount() async {
    Tuple2<String, String> result = await showDialog(
      context: context,
      builder: (context) => proxyUniverseAndCurrencyDialog(context),
    );
    if (result != null && Currency.isValidCurrency(result.item2)) {
      showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
      await bankingService.createProxyWallet(
        ownerProxyId: widget.appConfiguration.masterProxyId,
        proxyUniverse: result.item1,
        currency: result.item2,
      );
      _refreshAccounts();
      _refreshEnticements();
    }
  }

  Widget proxyUniverseAndCurrencyDialog(BuildContext context) {
    return SimpleDialog(
      title: Text('Choose Currency'),
      children: <Widget>[
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.PRODUCTION} ${Currency.INR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.PRODUCTION, Currency.INR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.PRODUCTION} ${Currency.EUR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.PRODUCTION, Currency.EUR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.TEST} ${Currency.INR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.TEST, Currency.INR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.TEST} ${Currency.EUR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.TEST, Currency.EUR));
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
          onTap: () => _deposit(context, account),
        ),
        new IconSlideAction(
          caption: 'Withdraw',
          color: Colors.indigo,
          icon: Icons.file_upload,
          onTap: () => _withdraw(context, account),
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

  void _deposit(BuildContext context, ProxyAccountEntity proxyAccount) async {
    String amount = await _acceptAmount(context);
    if (amount != null && double.tryParse(amount) != null) {
      String depositLink = await bankingService.depositLink(
        proxyAccount,
        Amount(proxyAccount.balance.currency, double.parse(amount)),
      );
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
      _refreshAccounts();
      _refreshEnticements();
    }
  }

  void _withdraw(BuildContext context, ProxyAccountEntity proxyAccount) async {
    List<ReceivingAccountEntity> receivingAccounts = await receivingAccountRepo.fetchAccountsForCurrency(
      proxyUniverse: proxyAccount.proxyUniverse,
      currency: proxyAccount.balance.currency,
    );
    ReceivingAccountEntity receivingAccountEntity;
    if (receivingAccounts.isEmpty) {
      receivingAccountEntity = await _createNewReceivingAccount(context);
    } else if (receivingAccounts.length == 1) {
      receivingAccountEntity = receivingAccounts.first;
    } else {
      receivingAccountEntity = await _chooseReceivingAccont(context, receivingAccounts);
    }
    if (receivingAccountEntity != null) {
      await bankingService.withdraw(proxyAccount, receivingAccountEntity);
      _refreshAccounts();
      _refreshEnticements();
    }
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

  Future<String> _acceptAmount(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String amount = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.enterAmountTitle),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(labelText: localizations.amount),
                onChanged: (value) {
                  amount = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.okButtonLabel),
              onPressed: () {
                Navigator.of(context).pop(amount);
              },
            ),
          ],
        );
      },
    );
  }

  void _manageReceivingAccounts() {
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new ReceivingAccounts(
                  appConfiguration: widget.appConfiguration,
                )));
  }


  Widget _chooseReceivingAccountDialog(BuildContext context, List<ReceivingAccountEntity> accounts) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return SimpleDialog(
      title: Text(localizations.chooseReceivingAccount),
      children:
          accounts.map((a) => SimpleDialogOption(
            child: new Text('${a.bank} - ${a.accountNumber ?? a.accountNumber}'),
            onPressed: () {
              Navigator.pop(context, a);
            },
          )).toList(),
    );
  }

  Future<ReceivingAccountEntity> _chooseReceivingAccont(BuildContext context, List<ReceivingAccountEntity> receivingAccounts) async {
    ReceivingAccountEntity receivingAccountEntity = await showDialog(
        context: context,
        builder: (context) => _chooseReceivingAccountDialog(context, receivingAccounts),
    );
    return receivingAccountEntity;
  }


  Future<ReceivingAccountEntity> _createNewReceivingAccount(BuildContext context) async {
    ReceivingAccountEntity receivingAccount = await Navigator.of(context).push(
        new MaterialPageRoute<ReceivingAccountEntity>(
            builder: (context) => ReceivingAccountDialog(),
            fullscreenDialog: true));
    if (receivingAccount != null) {
      receivingAccountRepo.save(receivingAccount);
    }
    return receivingAccount;
  }

}
