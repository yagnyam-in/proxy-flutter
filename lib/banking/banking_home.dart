import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/account_card.dart';
import 'package:proxy_flutter/banking/banking_service.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/banking/enticement_card.dart';
import 'package:proxy_flutter/banking/proxy_accounts_bloc.dart';
import 'package:proxy_flutter/banking/receiving_account_bloc.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/banking/receiving_accounts_page.dart';
import 'package:proxy_flutter/banking/service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_flutter/services/enticement_bloc.dart';
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
  final ProxyAccountsBloc _proxyAccountsBloc = BankingServiceFactory.proxyAccountsBloc();
  final BankingService _bankingService = BankingServiceFactory.bankingService();
  final ReceivingAccountBloc _receivingAccountBloc = BankingServiceFactory.receivingAccountBloc();
  final EnticementBloc _enticementBloc = ServiceFactory.enticementBloc();

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
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.bankingTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_balance),
            tooltip: localizations.receivingAccountsButtonHint,
            onPressed: _manageReceivingAccounts,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: StreamBuilder<List<ProxyAccountEntity>>(
            stream: _proxyAccountsBloc.accounts,
            initialData: [],
            builder: (BuildContext context, AsyncSnapshot<List<ProxyAccountEntity>> snapshot) {
              return accountsWidget(context, snapshot);
            }),
      ),
    );
  }

  Widget accountsWidget(BuildContext context, AsyncSnapshot<List<ProxyAccountEntity>> accounts) {
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
      accounts.data.forEach((account) {
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
          onPressed: () => _createAccountAndDeposit(context),
          icon: Icon(Icons.file_download),
          label: Text(localizations.deposit),
        ),
        RaisedButton.icon(
          onPressed: () => _payment(context),
          icon: Icon(Icons.file_upload),
          label: Text(localizations.payment),
        ),
      ],
    );
  }

  void _createAccountAndDeposit(BuildContext context) async {
    DepositRequestInput result = await _acceptDepositRequestInput(context);
    if (result != null) {
      showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
      ProxyAccountEntity proxyAccount = await _bankingService.createProxyWallet(
        ownerProxyId: widget.appConfiguration.masterProxyId,
        proxyUniverse: result.proxyUniverse,
        currency: result.amount.currency,
      );
      String depositLink = await _bankingService.depositLink(proxyAccount, result);
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  void _payment(BuildContext context) async {}

  void createNewAccount() async {
    Tuple2<String, String> result = await showDialog(
      context: context,
      builder: (context) => proxyUniverseAndCurrencyDialog(context),
    );
    if (result != null && Currency.isValidCurrency(result.item2)) {
      showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
      await _bankingService.createProxyWallet(
        ownerProxyId: widget.appConfiguration.masterProxyId,
        proxyUniverse: result.item1,
        currency: result.item2,
      );
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
          onTap: () => _depositToAccount(context, account),
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

  void _depositToAccount(BuildContext context, ProxyAccountEntity proxyAccount) async {
    DepositRequestInput input = await _acceptDepositRequestInput(context, proxyAccount);
    if (input != null) {
      String depositLink = await _bankingService.depositLink(
        proxyAccount,
        input,
      );
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  void _withdraw(BuildContext context, ProxyAccountEntity proxyAccount) async {
    List<ReceivingAccountEntity> receivingAccounts = await _receivingAccountBloc
        .getAccountsForCurrency(
          proxyUniverse: proxyAccount.proxyUniverse,
          currency: proxyAccount.balance.currency,
        )
        .single;
    ReceivingAccountEntity receivingAccountEntity;
    if (receivingAccounts.isEmpty) {
      receivingAccountEntity = await _createNewReceivingAccount(context);
    } else if (receivingAccounts.length == 1) {
      receivingAccountEntity = receivingAccounts.first;
    } else {
      receivingAccountEntity = await _chooseReceivingAccont(context, receivingAccounts);
    }
    if (receivingAccountEntity != null) {
      await _bankingService.withdraw(proxyAccount, receivingAccountEntity);
    }
  }

  void _archiveAccount(BuildContext context, ProxyAccountEntity proxyAccount) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (proxyAccount.balance.value != 0) {
      showToast(localizations.canNotDeleteActiveAccount);
      return;
    }
    _proxyAccountsBloc.deleteAccount(proxyAccount);
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
              _enticementBloc.dismissEnticement(enticement.enticementId);
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
      children: accounts
          .map((a) => SimpleDialogOption(
                child: new Text('${a.bank} - ${a.accountNumber ?? a.accountNumber}'),
                onPressed: () {
                  Navigator.pop(context, a);
                },
              ))
          .toList(),
    );
  }

  Future<ReceivingAccountEntity> _chooseReceivingAccont(
      BuildContext context, List<ReceivingAccountEntity> receivingAccounts) async {
    ReceivingAccountEntity receivingAccountEntity = await showDialog(
      context: context,
      builder: (context) => _chooseReceivingAccountDialog(context, receivingAccounts),
    );
    return receivingAccountEntity;
  }

  Future<ReceivingAccountEntity> _createNewReceivingAccount(BuildContext context) async {
    ReceivingAccountEntity receivingAccount = await Navigator.of(context).push(
        new MaterialPageRoute<ReceivingAccountEntity>(
            builder: (context) => ReceivingAccountDialog(), fullscreenDialog: true));
    if (receivingAccount != null) {
      _receivingAccountBloc.saveAccount(receivingAccount);
    }
    return receivingAccount;
  }

  Future<DepositRequestInput> _acceptDepositRequestInput(BuildContext context,
      [ProxyAccountEntity proxyAccount]) async {
    DepositRequestInput depositRequestInput =
        proxyAccount == null ? null : DepositRequestInput.forAccount(proxyAccount);
    DepositRequestInput result = await Navigator.of(context).push(MaterialPageRoute<DepositRequestInput>(
      builder: (context) => DepositRequestInputDialog(depositRequestInput: depositRequestInput),
      fullscreenDialog: true,
    ));
    return result;
  }
}
