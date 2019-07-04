import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/account_entity.dart';

class AccountStore with ProxyUtils, FirestoreUtils {
  DocumentReference _ref(String accountId) {
    return FirestoreUtils.accountRootRef(accountId);
  }

  AccountEntity _documentSnapshotToAccountEntity(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      return AccountEntity.fromJson(snapshot.data);
    }
    return null;
  }

  Future<AccountEntity> fetchAccount(String accountId) async {
    try {
      DocumentSnapshot snapshot = await _ref(accountId).get();
      return _documentSnapshotToAccountEntity(snapshot);
    } catch (e) {
      print("Error accessing $accountId: $e");
      return null;
    }
  }

  Stream<AccountEntity> subscribeForAccount(String accountId) {
    return _ref(accountId).snapshots().map(_documentSnapshotToAccountEntity);
  }

  Future<void> saveAccount(AccountEntity account, {Transaction transaction}) async {
    var ref = _ref(account.accountId);
    var data = account.toJson();
    if (transaction == null) {
      return ref.setData(data);
    } else {
      return transaction.set(ref, data);
    }
  }
}
