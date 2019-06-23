import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/proxy_key_entity.dart';

class ProxyKeyStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference _root;

  ProxyKeyStore(this.appConfiguration) : _root = FirestoreUtils.rootRef(appConfiguration.firebaseUser);

  CollectionReference _proxiesRef() {
    return _root.collection('proxy-key');
  }

  DocumentReference _ref(ProxyId proxyId) {
    return _proxiesRef().document(proxyId.uniqueId);
  }

  Future<ProxyKey> fetchProxyKey(ProxyId proxyId) async {
    ProxyKeyEntity proxyKeyEntity = await _fetchProxyKeyEntity(proxyId);
    return proxyKeyEntity?.proxyKey;
  }

  Future<void> updateFcmToken(ProxyKey proxyKey, String fcmToken) async {
    return _insertProxyKeyEntity(ProxyKeyEntity(
      proxyKey: proxyKey,
      fcmToken: fcmToken,
    ));
  }

  Future<bool> hasProxyKey(ProxyId proxyId) async {
    ProxyKeyEntity proxyKeyEntity = await _fetchProxyKeyEntity(proxyId);
    return proxyKeyEntity != null;
  }

  Future<ProxyKeyEntity> _fetchProxyKeyEntity(ProxyId proxyId) async {
    DocumentSnapshot snapshot = await _ref(proxyId).get();
    return _documentSnapshotToProxyKey(snapshot);
  }

  Future<void> _insertProxyKeyEntity(ProxyKeyEntity proxyKeyEntity) async {
    await _ref(proxyKeyEntity.proxyId).setData(proxyKeyEntity.toJson());
  }

  Future<void> insertProxyKey(ProxyKey proxyKey) {
    print('insert Proxy Key $proxyKey');
    return _insertProxyKeyEntity(ProxyKeyEntity(proxyKey: proxyKey));
  }

  Future<List<ProxyKey>> fetchProxiesWithoutFcmToken(String fcmToken) async {
    var snapshot = await _proxiesRef().where("fcmToken", isNull: true).getDocuments();
    return _querySnapshotToProxyKeys(snapshot).takeWhile((e) => e.fcmToken != fcmToken).map((e) => e.proxyKey).toList();
  }

  ProxyKeyEntity _documentSnapshotToProxyKey(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return ProxyKeyEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<ProxyKeyEntity> _querySnapshotToProxyKeys(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToProxyKey).takeWhile((a) => a != null).toList();
    } else {
      return [];
    }
  }
}
