import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/account_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_flutter/services/proxy_key_store_impl.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';

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
  final ProxyKeyStoreImpl proxyKeyStore = ProxyKeyStoreImpl();
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();

  bool _isLoading = false;
  bool _isInError = false;
  List<ProxyAccountEntity> _accounts;
  List<EnticementEntity> _enticements;

  @override
  void initState() {
    super.initState();
  }


  void setEnticements(List<EnticementEntity> enticements, {bool isInError = false}) {
    setState(() {
      _enticements = enticements;
      _isInError = isInError;
      _isLoading = _enticements != null && _accounts != null;
    });
  }


  void setAccounts(List<ProxyAccountEntity> accounts, {bool isInError = false}) {
    setState(() {
      _accounts = accounts;
      _isInError = isInError;
      _isLoading = _enticements != null && _accounts != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ProxyAccountRepo.instance(DB.instance()).fetchAccounts().then((accounts) {
      setAccounts(accounts);
    }, onError: (e) {
      setAccounts([], isInError: true);
    });
    EnticementFactory.instance().getEnticements(context).then((enticements) {
      setEnticements(enticements);
    });

    double childOpacity = _isLoading ? 0.5 : 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(ProxyLocalizations.of(context).bankingTitle),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          children: <Widget>[
            actionBar(context),
            const SizedBox(height: 16.0),
            accounts(context),
            const SizedBox(height: 16.0),
          ],
        )
      ),
    );
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

  Widget accounts(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (_accounts != null && _accounts.isNotEmpty) {
      return Accounts(accounts: _accounts);
    } else {
      return Text(localizations.startBanking);
    }
  }

  Widget enticements(BuildContext context) {

  }

  void deposit() {
    if (_accounts.isEmpty) {

    }
  }


  void payment() {

  }

}

class Enticements extends StatelessWidget {
  final List<EnticementEntity> enticements;

  const Enticements({Key key, this.enticements}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
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
