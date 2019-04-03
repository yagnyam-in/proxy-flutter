import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_messages/banking.dart';
import 'package:rxdart/rxdart.dart';

class ProxyAccountsBloc {
  final ProxyAccountRepo _proxyAccountRepo;
  final BehaviorSubject<List<ProxyAccountEntity>> _accountStreamController =
      BehaviorSubject<List<ProxyAccountEntity>>();

  ProxyAccountsBloc({@required ProxyAccountRepo proxyAccountRepo}) : _proxyAccountRepo = proxyAccountRepo {
    assert(this._proxyAccountRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing proxy accounts");
    _proxyAccountRepo.fetchAccounts().then(
      (accounts) {
        print("Sending $accounts to stream");
        _accountStreamController.sink.add(accounts);
      },
      onError: (e) {
        print("Error fetching proxy Accounts $e");
      },
    );
  }

  Stream<List<ProxyAccountEntity>> get accounts {
    return _accountStreamController;
  }

  Future<void> saveAccount(ProxyAccountEntity proxyAccount) async {
    print("save account $proxyAccount");
    await _proxyAccountRepo.saveAccount(proxyAccount);
    _refresh();
  }

  Future<void> deleteAccount(ProxyAccountEntity proxyAccount) async {
    print("delete account $proxyAccount");
    await _proxyAccountRepo.deleteAccount(proxyAccount);
    _refresh();
  }

  Future<ProxyAccountEntity> fetchAccount(ProxyAccountId accountId) {
    return _proxyAccountRepo.fetchAccount(accountId);
  }

  void dispose() {
    print('closing _accountStreamController');
    _accountStreamController.close();
  }
}
