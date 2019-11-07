import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/bank_entity.dart';
import 'package:promo/db/firestore_utils.dart';

class BankStore with ProxyUtils, FirestoreUtils {
  final CollectionReference banksRoot;

  BankStore() : banksRoot = Firestore.instance.collection('/banks');

  Future<BankEntity> fetchBank({@required String proxyUniverse, ProxyId bankProxyId, String bankId}) async {
    var query = banksRoot.where(BankEntity.PROXY_UNIVERSE, isEqualTo: proxyUniverse);
    if (bankProxyId != null) {
      query = query
          .where(BankEntity.BANK_ID, isEqualTo: bankProxyId.id)
          .where(BankEntity.BANK_SHA256_THUMBPRINT, isEqualTo: bankProxyId.sha256Thumbprint);
    } else if (bankId != null) {
      query = query.where(BankEntity.BANK_ID, isEqualTo: bankId);
    } else {
      throw ArgumentError("Either bankId or bankProxyId must be specified");
    }
    print(
        "fetchBank(proxyUniverse: $proxyUniverse, bankProxyId: $bankProxyId, bankId: $bankId) => ${query.buildArguments()}");
    return _querySnapshotToAccounts(await query.getDocuments()).first;
  }

  BankEntity _documentSnapshotToAccount(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return BankEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<BankEntity> _querySnapshotToAccounts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAccount).where((a) => a != null).toList();
    } else {
      return [];
    }
  }
}
