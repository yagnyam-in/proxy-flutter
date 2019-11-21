import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/receiving_account_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:quiver/strings.dart';

import 'abstract_store.dart';

class ReceivingAccountStore extends AbstractStore<ReceivingAccountEntity> {
  ReceivingAccountStore(AppConfiguration appConfiguration) : super(appConfiguration) {
    assert(appConfiguration != null);
  }

  @override
  FromJson<ReceivingAccountEntity> get fromJson => ReceivingAccountEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('receiving-accounts');
  }

  Stream<List<ReceivingAccountEntity>> subscribeForAccounts({
    @required String proxyUniverse,
    @required String currency,
  }) {
    Query query = rootCollection
        .where(ReceivingAccountEntity.PROXY_UNIVERSE, isEqualTo: proxyUniverse)
        .where(ReceivingAccountEntity.ACTIVE, isEqualTo: true);
    if (isNotBlank(currency)) {
      query = query.where(ReceivingAccountEntity.CURRENCY, isEqualTo: currency);
    }
    return query.snapshots().map(querySnapshotToEntityList);
  }
}
