import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/dismissed_enticement_entity.dart';

class DismissedEnticementStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  DismissedEnticementStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference enticementsRef() {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(appConfiguration.proxyUniverse)
        .collection('dismissed-enticements');
  }

  DocumentReference ref(String enticementId) {
    return enticementsRef().document(enticementId);
  }

  Stream<List<DismissedEnticementEntity>> subscribeForEnticements() {
    print("Subscribing for dismissed enticements");
    return enticementsRef().snapshots().map(_querySnapshotToEntitys);
  }

  Future<List<DismissedEnticementEntity>> fetchEnticements() async {
    print("Fetching all dismissed enticements");
    return _querySnapshotToEntitys(await enticementsRef().getDocuments());
  }

  DismissedEnticementEntity _documentSnapshotToEntity(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return DismissedEnticementEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<DismissedEnticementEntity> _querySnapshotToEntitys(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToEntity).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<DismissedEnticementEntity> saveEnticement(DismissedEnticementEntity enticement) async {
    await ref(enticement.id).setData(enticement.toJson());
    return enticement;
  }
}
