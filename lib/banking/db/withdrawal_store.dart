import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/banking/model/withdrawal_event.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';

class WithdrawalStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final EventStore _eventStore;

  WithdrawalStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId),
        _eventStore = EventStore(appConfiguration);

  DocumentReference ref({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('withdrawals')
        .document(withdrawalId);
  }

  Future<WithdrawalEntity> fetchWithdrawal({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) async {
    DocumentSnapshot snapshot = await ref(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    ).get();
    if (snapshot.exists) {
      return WithdrawalEntity.fromJson(snapshot.data);
    }
    return null;
  }

  Stream<WithdrawalEntity> subscribeForWithdrawal({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) {
    return ref(
      proxyUniverse: proxyUniverse,
      withdrawalId: withdrawalId,
    ).snapshots().map(
          (s) => s.exists ? WithdrawalEntity.fromJson(s.data) : null,
        );
  }

  Future<WithdrawalEntity> saveWithdrawal(WithdrawalEntity withdrawal) async {
    await ref(
      proxyUniverse: withdrawal.proxyUniverse,
      withdrawalId: withdrawal.withdrawalId,
    ).setData(withdrawal.toJson());
    await _eventStore.saveEvent(WithdrawalEvent.fromWithdrawalEntity(withdrawal));
    return withdrawal;
  }
}
