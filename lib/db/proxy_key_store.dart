import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/proxy_key_entity.dart';

class ProxyKeyStore with ProxyUtils, FirestoreUtils {
  final AccountEntity account;

  ProxyKeyStore(this.account);

  CollectionReference _proxiesRef() {
    return FirestoreUtils.accountRootRef(account.accountId).collection('proxy-key');
  }

  DocumentReference _ref(ProxyId proxyId) {
    return _proxiesRef().document(proxyId.uniqueId);
  }

  Future<ProxyKey> fetchProxyKey(ProxyId proxyId) async {
    ProxyKeyEntity proxyKeyEntity = await _fetchProxyKeyEntity(proxyId);
    if (proxyKeyEntity != null) {
      return _proxyKeyEntityToProxyKey(proxyKeyEntity);
    }
    return null;
  }

  Future<void> updateFcmToken(ProxyKey proxyKey, String fcmToken) async {
    return _ref(proxyKey.id).setData({
      'fcmToken': fcmToken,
    }, merge: true);
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
    await _ref(proxyKeyEntity.id).setData(proxyKeyEntity.toJson());
  }

  Future<void> insertProxyKey(ProxyKey proxyKey) {
    print('insert Proxy Key $proxyKey');
    return _insertProxyKeyEntity(_proxyKeyToProxyKeyEntity(proxyKey));
  }

  Future<List<ProxyKey>> fetchProxiesWithoutFcmToken(String fcmToken) async {
    var snapshot = await _proxiesRef().where("fcmToken", isNull: true).getDocuments();
    return _querySnapshotToProxyKeys(snapshot)
        .takeWhile((e) => e.fcmToken != fcmToken)
        .map((e) => _proxyKeyEntityToProxyKey(e))
        .toList();
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

  ProxyKey _proxyKeyEntityToProxyKey(ProxyKeyEntity keyEntity) {
    return ProxyKey(
      id: keyEntity.id,
      name: keyEntity.name,
      localAlias: keyEntity.localAlias,
      privateKeyEncoded: _decrypt(
        encryptionAlgorithm: keyEntity.encryptionAlgorithm,
        cipherText: keyEntity.encryptedPrivateKeyEncoded,
      ),
      privateKeySha256Thumbprint: keyEntity.privateKeySha256Thumbprint,
      publicKeyEncoded: keyEntity.publicKeyEncoded,
      publicKeySha256Thumbprint: keyEntity.publicKeySha256Thumbprint,
    );
  }

  ProxyKeyEntity _proxyKeyToProxyKeyEntity(ProxyKey key) {
    return ProxyKeyEntity(
      id: key.id,
      name: key.name,
      localAlias: key.localAlias,
      encryptionAlgorithm: ENCRYPTION_ALGORITHM,
      encryptedPrivateKeyEncoded: _encrypt(
        encryptionAlgorithm: ENCRYPTION_ALGORITHM,
        plainText: key.privateKeyEncoded,
      ),
      privateKeySha256Thumbprint: key.privateKeySha256Thumbprint,
      publicKeyEncoded: key.publicKeyEncoded,
      publicKeySha256Thumbprint: key.publicKeySha256Thumbprint,
    );
  }

  String get _encryptionKey {
    assert(AppConfiguration.passPhrase != null);
    return AppConfiguration.passPhrase;
  }

  // TODO: Revisit
  Key get _adjustedKey {
    String adjusted = _encryptionKey;
    Key key = Key.fromUtf8(adjusted);
    int len = key.bytes.lengthInBytes;
    if ({16, 24, 32}.contains(len)) {
      return key;
    } else if (len < 16) {
      adjusted = adjusted.padRight(16, '0');
    } else if (len < 24) {
      adjusted = adjusted.padRight(24, '0');
    } else if (len < 32) {
      adjusted = adjusted.padRight(32, '0');
    } else {
      throw ArgumentError("Invalid length $len for pass phrase");
    }
    return Key.fromUtf8(adjusted);
  }

  // TODO: Revisit
  Encrypter _cipher(String encryptionAlgorithm) {
    if (encryptionAlgorithm == ENCRYPTION_ALGORITHM) {
      return Encrypter(AES(_adjustedKey, mode: AESMode.ctr));
    }
    throw ArgumentError("Invalid encryptionAlgorithm $encryptionAlgorithm");
  }

  String _encrypt({
    @required String encryptionAlgorithm,
    @required String plainText,
  }) {
    final iv = IV.fromLength(16);
    return _cipher(encryptionAlgorithm).encrypt(plainText, iv: iv).base64;
  }

  String _decrypt({
    @required String encryptionAlgorithm,
    @required String cipherText,
  }) {
    final iv = IV.fromLength(16);
    return _cipher(encryptionAlgorithm).decrypt64(cipherText, iv: iv);
  }

  static const String ENCRYPTION_ALGORITHM = 'AES/CTR/NoPadding';
}
