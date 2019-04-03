import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:rxdart/rxdart.dart';

class ReceivingAccountBloc {
  final ReceivingAccountRepo _receivingAccountRepo;
  final BehaviorSubject<List<ReceivingAccountEntity>> _accountStreamController =
      BehaviorSubject<List<ReceivingAccountEntity>>();

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
    return _accountStreamController;
  }

  Future<void> saveAccount(ReceivingAccountEntity receivingAccount) async {
    _receivingAccountRepo.save(receivingAccount);
    _refresh();
  }

  void dispose() {
    _accountStreamController?.close();
  }
}
