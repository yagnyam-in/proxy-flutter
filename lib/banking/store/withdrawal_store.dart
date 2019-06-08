import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';

import 'package:proxy_flutter/db/firestore_utils.dart';

class WithdrawalStore with ProxyUtils, FirestoreUtils {
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

  final DocumentReference root;

  WithdrawalStore({
    @required this.root,
  }) {
    assert(root != null);
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

  Future<WithdrawalEntity> saveWithdrawal(WithdrawalEntity withdrawal) async {
    await ref(
      proxyUniverse: withdrawal.proxyUniverse,
      withdrawalId: withdrawal.withdrawalId,
    ).setData(withdrawal.toJson());
    return withdrawal;
  }
}
