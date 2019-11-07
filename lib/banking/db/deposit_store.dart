import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/deposit_entity.dart';
import 'package:promo/banking/model/deposit_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';

import 'cleanup_service.dart';

class DepositStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final EventStore _eventStore;
  final CleanupService _cleanupService;

  DepositStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId),
        _eventStore = EventStore(appConfiguration),
        _cleanupService = CleanupService(appConfiguration);

  DocumentReference _ref({
    @required String proxyUniverse,
    @required String depositId,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('deposits')
        .document(depositId);
  }

  Future<DepositEntity> fetchDeposit({
    @required String proxyUniverse,
    @required String depositId,
  }) async {
    DocumentSnapshot snapshot = await _ref(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    ).get();
    if (snapshot.exists) {
      return DepositEntity.fromJson(snapshot.data);
    }
    return null;
  }

  Stream<DepositEntity> subscribeForDeposit({
    @required String proxyUniverse,
    @required String depositId,
  }) {
    return _ref(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    ).snapshots().map(
          (s) => s.exists ? DepositEntity.fromJson(s.data) : null,
        );
  }

  Future<DepositEntity> saveDeposit(DepositEntity deposit) async {
    final ref = _ref(proxyUniverse: deposit.proxyUniverse, depositId: deposit.depositId);
    await Future.wait([
      ref.setData(deposit.toJson()),
      _eventStore.saveEvent(DepositEvent.fromDepositEntity(deposit)),
      _cleanupService.onDeposit(deposit)
    ]);
    return deposit;
  }
}
