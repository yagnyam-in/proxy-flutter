import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/store/event_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class DepositStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final EventStore _eventStore;

  DepositStore(this.appConfiguration)
      : root = FirestoreUtils.rootRef(appConfiguration.firebaseUser),
        _eventStore = EventStore(appConfiguration);

  DocumentReference ref({
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
    DocumentSnapshot snapshot = await ref(
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
    return ref(
      proxyUniverse: proxyUniverse,
      depositId: depositId,
    ).snapshots().map(
          (s) => s.exists ? DepositEntity.fromJson(s.data) : null,
        );
  }

  Future<DepositEntity> saveDeposit(DepositEntity deposit) async {
    await ref(
      proxyUniverse: deposit.proxyUniverse,
      depositId: deposit.depositId,
    ).setData(deposit.toJson());
    await _eventStore.saveEvent(DepositEvent.fromDepositEntity(deposit));
    return deposit;
  }
}
