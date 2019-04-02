import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';

class ReceivingAccountBloc {
  final ReceivingAccountRepo _receivingAccountRepo;
  final _accountStreamController = StreamController<List<ReceivingAccountEntity>>.broadcast();

  ReceivingAccountBloc({@required ReceivingAccountRepo receivingAccountRepo})
      : _receivingAccountRepo = receivingAccountRepo {
    assert(this._receivingAccountRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing receiving accounts");
    _receivingAccountRepo.fetchAccounts().then(
      (r) {
        _accountStreamController.sink.add(r);
      },
      onError: (e) {
        print("Failed to fetch Receiving Accounts");
      },
    );
  }

  Stream<List<ReceivingAccountEntity>> get accounts {
    return _accountStreamController.stream;
  }

  Stream<List<ReceivingAccountEntity>> getAccountsForCurrency(
      {@required String proxyUniverse, @required String currency}) {
    assert(proxyUniverse != null);
    assert(currency != null);
    return _accountStreamController.stream
        .map((r) => r.where((a) => a.proxyUniverse == proxyUniverse && a.currency == currency).toList());
  }

  Future<void> saveAccount(ReceivingAccountEntity receivingAccount) async {
    _receivingAccountRepo.save(receivingAccount);
    _refresh();
  }

  void dispose() {
    _accountStreamController.close();
  }
}
