import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/abstract_entity.dart';
import 'package:promo/banking/model/proxy_account_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:quiver/strings.dart';

import 'abstract_store.dart';
import 'cleanup_service.dart';

class ProxyAccountStore extends AbstractStore<ProxyAccountEntity> {
  final CleanupService _cleanupService;

  ProxyAccountStore(AppConfiguration appConfiguration)
      : _cleanupService = CleanupService(appConfiguration),
        super(appConfiguration) {
    assert(appConfiguration != null);
  }

  @override
  FromJson<ProxyAccountEntity> get fromJson => ProxyAccountEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('proxy-accounts');
  }

  Stream<List<ProxyAccountEntity>> subscribeForAccounts({@required String proxyUniverse}) {
    Query query = rootCollection
        .where(ProxyAccountEntity.PROXY_UNIVERSE, isEqualTo: proxyUniverse)
        .where(ProxyAccountEntity.ACTIVE, isEqualTo: true);
    return query.snapshots().map(querySnapshotToEntityList);
  }

  Stream<ProxyAccountEntity> subscribe(ProxyAccountId proxyAccountId) {
    Query query = rootCollection
        .where(ProxyAccountEntity.ACCOUNT_ID, isEqualTo: proxyAccountId.accountId)
        .where(ProxyAccountEntity.BANK_ID, isEqualTo: proxyAccountId.bankId);
    return query.snapshots().map((s) => firstResult(s, query));
  }

  Future<ProxyAccountEntity> fetchAccount({ProxyAccountId proxyAccountId}) async {
    Query query = rootCollection
        .where(ProxyAccountEntity.ACCOUNT_ID, isEqualTo: proxyAccountId.accountId)
        .where(ProxyAccountEntity.BANK_ID, isEqualTo: proxyAccountId.bankId);
    return firstResult(await query.getDocuments(), query);
  }

  Future<List<ProxyAccountEntity>> fetchActiveAccounts({
    @required String proxyUniverse,
    @required String currency,
    String bankId,
  }) async {
    Query query = rootCollection
        .where(ProxyAccountEntity.PROXY_UNIVERSE, isEqualTo: proxyUniverse)
        .where(ProxyAccountEntity.CURRENCY, isEqualTo: currency)
        .where(AbstractEntity.ACTIVE, isEqualTo: true);
    if (isNotEmpty(bankId)) {
      query = query.where(ProxyAccountEntity.BANK_ID, isEqualTo: bankId);
    }
    return querySnapshotToEntityList(await query.getDocuments());
  }

  @override
  Future<ProxyAccountEntity> save(ProxyAccountEntity account, {Transaction transaction}) async {
    account = await super.save(account, transaction: transaction);
    await Future.wait([
      _cleanupService.onProxyAccount(account),
    ]);
    return account;
  }
}
