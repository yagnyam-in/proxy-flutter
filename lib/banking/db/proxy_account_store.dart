import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_messages/banking.dart';

import 'cleanup_service.dart';

class ProxyAccountStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final CleanupService _cleanupService;

  ProxyAccountStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId),
        _cleanupService = CleanupService(appConfiguration) {
    assert(appConfiguration != null);
  }

  CollectionReference _accountsRef({
    @required String proxyUniverse,
  }) {
    return root.collection(FirestoreUtils.PROXY_UNIVERSE_NODE).document(proxyUniverse).collection('proxy-accounts');
  }

  DocumentReference _ref({
    @required String proxyUniverse,
    @required String accountId,
  }) {
    return _accountsRef(proxyUniverse: proxyUniverse).document(accountId);
  }

  Stream<List<ProxyAccountEntity>> subscribeForAccounts() {
    return _accountsRef(proxyUniverse: appConfiguration.proxyUniverse)
        .where(ProxyAccountEntity.ACTIVE, isEqualTo: true)
        .snapshots()
        .map(_querySnapshotToAccounts);
  }

  Stream<ProxyAccountEntity> subscribeForAccount(ProxyAccountId accountId) {
    return _ref(proxyUniverse: accountId.proxyUniverse, accountId: accountId.accountId)
        .snapshots()
        .map(_documentSnapshotToAccount);
  }

  Future<ProxyAccountEntity> fetchAccount(ProxyAccountId accountId) async {
    DocumentSnapshot doc = await _ref(proxyUniverse: accountId.proxyUniverse, accountId: accountId.accountId).get();
    return _documentSnapshotToAccount(doc);
  }

  Future<List<ProxyAccountEntity>> fetchActiveAccounts({
    @required ProxyId masterProxyId,
    @required String proxyUniverse,
    @required String currency,
  }) async {
    QuerySnapshot querySnapshot = await _accountsRef(proxyUniverse: proxyUniverse)
        .where(ProxyAccountEntity.ID_OF_OWNER_PROXY_ID, isEqualTo: masterProxyId.id)
        .where(ProxyAccountEntity.CURRENCY, isEqualTo: currency)
        .where(ProxyAccountEntity.ACTIVE, isEqualTo: true)
        .getDocuments();
    return _querySnapshotToAccounts(querySnapshot).where((a) => a.ownerProxyId == masterProxyId).toList();
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
      return snapshot.documents.map(_documentSnapshotToAccount).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<ProxyAccountEntity> saveAccount(ProxyAccountEntity account) async {
    final ref = _ref(proxyUniverse: account.proxyUniverse, accountId: account.accountId.accountId);
    await Future.wait([
      ref.setData(account.toJson()),
      _cleanupService.onProxyAccount(account),
    ]);
    return account;
  }

  Future<void> deleteAccount(ProxyAccountEntity account) {
    return _ref(
      proxyUniverse: account.proxyUniverse,
      accountId: account.accountId.accountId,
    ).delete();
  }
}
