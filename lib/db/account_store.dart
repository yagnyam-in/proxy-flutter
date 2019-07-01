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
    DocumentSnapshot snapshot = await _ref(accountId).get();
    return _documentSnapshotToAccountEntity(snapshot);
  }

  Stream<AccountEntity> subscribeForAccount(String accountId) {
    return _ref(accountId).snapshots().map(_documentSnapshotToAccountEntity);
  }

  Future<AccountEntity> saveAccount(AccountEntity account, {Transaction transaction}) async {
    if (transaction == null) {
      await _ref(account.accountId).setData(account.toJson());
    } else {
      transaction.set(_ref(account.accountId), account.toJson());
    }
    return account;
  }
}