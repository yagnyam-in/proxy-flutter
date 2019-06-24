import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_messages/banking.dart';

class ProxyAccountStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  ProxyAccountStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId) {
    assert(appConfiguration != null);
  }

  CollectionReference accountsRef({
    @required String proxyUniverse,
  }) {
    return root.collection(FirestoreUtils.PROXY_UNIVERSE_NODE).document(proxyUniverse).collection('proxy-accounts');
  }

  DocumentReference ref({
    @required String proxyUniverse,
    @required String accountId,
  }) {
    return accountsRef(proxyUniverse: proxyUniverse).document(accountId);
  }

  Stream<List<ProxyAccountEntity>> subscribeForAccounts() {
    return accountsRef(proxyUniverse: appConfiguration.proxyUniverse).snapshots().map(_querySnapshotToAccounts);
  }

  Stream<ProxyAccountEntity> subscribeForAccount(ProxyAccountId accountId) {
    return ref(proxyUniverse: accountId.proxyUniverse, accountId: accountId.accountId)
        .snapshots()
        .map(_documentSnapshotToAccount);
  }

  Future<ProxyAccountEntity> fetchAccount(ProxyAccountId accountId) async {
    DocumentSnapshot doc = await ref(proxyUniverse: accountId.proxyUniverse, accountId: accountId.accountId).get();
    return _documentSnapshotToAccount(doc);
  }

  ProxyAccountEntity _documentSnapshotToAccount(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return ProxyAccountEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<ProxyAccountEntity> _querySnapshotToAccounts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAccount).takeWhile((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<ProxyAccountEntity> saveAccount(ProxyAccountEntity account) async {
    await ref(
      proxyUniverse: account.proxyUniverse,
      accountId: account.accountId.accountId,
    ).setData(account.toJson());
    return account;
  }

  Future<void> deleteAccount(ProxyAccountEntity account) {
    return ref(
      proxyUniverse: account.proxyUniverse,
      accountId: account.accountId.accountId,
    ).delete();
  }
}
