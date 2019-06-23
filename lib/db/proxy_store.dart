import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/proxy_entity.dart';

class ProxyStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference _root;

  ProxyStore(this.appConfiguration) : _root = FirestoreUtils.rootRef(appConfiguration.firebaseUser);

  CollectionReference _proxiesRef() {
    return _root.collection('proxy');
  }

  DocumentReference _ref(ProxyId proxyId) {
    return _proxiesRef().document(proxyId.uniqueId);
  }

  Future<ProxyEntity> _fetchProxyEntity(ProxyId proxyId) async {
    DocumentSnapshot snapshot = await _ref(proxyId).get();
    if (snapshot.exists) {
      return ProxyEntity.fromJson(snapshot.data);
    }
    return null;
  }

  Future<Proxy> fetchProxy(ProxyId proxyId) async {
    ProxyEntity proxyEntity = await _fetchProxyEntity(proxyId);
    return proxyEntity?.proxy;
  }

  Future<void> _insertProxyEntity(ProxyEntity proxyEntity) async {
    await _ref(proxyEntity.proxyId).setData(proxyEntity.toJson());
  }

  Future<void> insertProxy(Proxy proxy) async {
    await _insertProxyEntity(ProxyEntity(proxy: proxy));
  }
}
