import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_messages/banking.dart';

class ProxyAccountsBloc {
  final ProxyAccountRepo _proxyAccountRepo;
  final _accountStreamController = StreamController<List<ProxyAccountEntity>>.broadcast();

  ProxyAccountsBloc({@required ProxyAccountRepo proxyAccountRepo}) : _proxyAccountRepo = proxyAccountRepo {
    assert(this._proxyAccountRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing proxy accounts");
    _proxyAccountRepo.fetchAccounts().then(
      (r) {
        print("Got ${r.length} accounts");
        _accountStreamController.sink.add(r);
      },
      onError: (e) {
        print("Failed to fetch Receiving Accounts");
      },
    );
  }

  Stream<List<ProxyAccountEntity>> get accounts {
    return _accountStreamController.stream;
  }

  Future<void> saveAccount(ProxyAccountEntity proxyAccount) async {
    print("save account $proxyAccount");
    _proxyAccountRepo.saveAccount(proxyAccount);
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
    _accountStreamController.close();
  }
}
