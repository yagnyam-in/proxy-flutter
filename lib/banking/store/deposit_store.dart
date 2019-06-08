import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class DepositStore with ProxyUtils, FirestoreUtils {
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

  final FirebaseUser firebaseUser;
  final DocumentReference root;

  DepositStore({
    @required this.firebaseUser,
  }) : root = FirestoreUtils.rootRef(firebaseUser) {
    assert(firebaseUser != null);
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

  Future<DepositEntity> saveDeposit(DepositEntity deposit) async {
    await ref(
      proxyUniverse: deposit.proxyUniverse,
      depositId: deposit.depositId,
    ).setData(deposit.toJson());
    return deposit;
  }
}
