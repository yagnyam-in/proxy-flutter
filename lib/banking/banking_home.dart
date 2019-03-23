import 'package:flutter/material.dart';
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
import 'package:proxy_flutter/services/proxy_key_store_impl.dart';
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
    EnticementFactory.instance().getEnticement(context).then((enticement) {
      _setEnticement(enticement);
    }, onError: (e) {
      print(e);
      _setEnticement(null);
    });
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
            children: rows(),
          )),
    );
  }

  List<Widget> rows() {
    List<Widget> rows = [
      actionBar(context),
    ];
    if (_accounts != null && _accounts.isNotEmpty) {
      print("adding ${_accounts.length} accounts");
      _accounts.forEach((a) {
        rows.addAll([
          const SizedBox(height: 16.0),
          AccountCard(account: a),
        ]);
      });
    }
    if (_enticement != null) {
      rows.addAll([
        const SizedBox(height: 16.0),
        EnticementCard(enticement: _enticement),
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
    showToast(ProxyLocalizations.of(context).creatingAnonymousAccount);
    String currency = await showDialog(
      context: context,
      builder: (context) => currencyDialog(context),
    );
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(widget.appConfiguration.masterProxyId);
    await bankingService.createProxyWallet(proxyKey, currency);
    _refreshAccounts();
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
        SimpleDialogOption(
          child: new Text('Cancel'),
          onPressed: () {
            Navigator.pop(context, '');
          },
        ),
      ],
    );
  }
}

class Accounts extends StatelessWidget {
  final List<ProxyAccountEntity> accounts;

  const Accounts({Key key, this.accounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // padding: EdgeInsets.all(8.0),
      itemExtent: 20.0,
      itemBuilder: (BuildContext context, int index) {
        return AccountCard(account: accounts[index]);
      },
    );
  }
}
