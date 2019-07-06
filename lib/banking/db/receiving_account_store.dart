import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class ReceivingAccountStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  ReceivingAccountStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId) {
    assert(appConfiguration != null);
  }

  CollectionReference accountsRef() {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(appConfiguration.proxyUniverse)
        .collection('receiving-accounts');
  }

  DocumentReference ref({
    @required String accountId,
  }) {
    return accountsRef().document(accountId);
  }

  Stream<List<ReceivingAccountEntity>> subscribeForAccounts({String currency}) {
    Query query = currency == null ? accountsRef() : accountsRef().where('currency', isEqualTo: currency);
    return query.snapshots().map(_querySnapshotToAccounts);
  }

  Stream<ReceivingAccountEntity> subscribeForAccount({@required String accountId}) {
    return ref(accountId: accountId).snapshots().map(_documentSnapshotToAccount);
  }

  Future<ReceivingAccountEntity> fetchAccount({@required String accountId}) async {
    DocumentSnapshot doc = await ref(accountId: accountId).get();
    return _documentSnapshotToAccount(doc);
  }

  ReceivingAccountEntity _documentSnapshotToAccount(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return ReceivingAccountEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<ReceivingAccountEntity> _querySnapshotToAccounts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAccount).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<ReceivingAccountEntity> saveAccount(ReceivingAccountEntity account) async {
    print("Saving $account");
    assert(account.proxyUniverse == appConfiguration.proxyUniverse);
    await ref(
      accountId: account.accountId,
    ).setData(account.toJson());
    return account;
  }

  Future<void> archiveAccount(ReceivingAccountEntity account) {
    assert(account.proxyUniverse == appConfiguration.proxyUniverse);
    return ref(
      accountId: account.accountId,
    ).delete();
  }
}
