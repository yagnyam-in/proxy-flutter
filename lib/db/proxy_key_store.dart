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
  final String passPhrase;

  ProxyKeyStore.forAccount(this.account, this.passPhrase) {
    assert(account != null);
    assert(passPhrase != null);
  }

  ProxyKeyStore(AppConfiguration appConfiguration)
      : account = appConfiguration.account,
        passPhrase = appConfiguration.passPhrase {
    assert(account != null);
    assert(passPhrase != null);
  }

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

  Future<void> _insertProxyKeyEntity(ProxyKeyEntity proxyKeyEntity, {Transaction transaction}) {
    var ref = _ref(proxyKeyEntity.id);
    var data = proxyKeyEntity.toJson();
    if (transaction != null) {
      return transaction.set(ref, data);
    } else {
      return ref.setData(data);
    }
  }

  Future<void> insertProxyKey(ProxyKey proxyKey, {Transaction transaction}) async {
    print('insert Proxy Key $proxyKey');
    return _insertProxyKeyEntity(
      await _proxyKeyToProxyKeyEntity(proxyKey),
      transaction: transaction,
    );
  }

  Future<List<ProxyKey>> fetchProxiesWithoutFcmToken(String fcmToken) async {
    print('fetchProxiesWithoutFcmToken $fcmToken');
    List<Future<QuerySnapshot>> snapshotFutures = [
      _proxiesRef().where("fcmToken", isNull: true).getDocuments(),
      _proxiesRef().where("fcmToken", isLessThan: fcmToken).getDocuments(),
      _proxiesRef().where("fcmToken", isGreaterThan: fcmToken).getDocuments(),
    ];
    List<QuerySnapshot> snapshots = await Future.wait(snapshotFutures);
    List<Future<ProxyKey>> keys = snapshots.expand((snapshot) {
      return _querySnapshotToProxyKeys(snapshot)
          .where((e) => e.fcmToken != fcmToken)
          .map((e) async => await _proxyKeyEntityToProxyKey(e))
          .toList();
    }).toList();
    return Future.wait(keys);
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
      return snapshot.documents.map(_documentSnapshotToProxyKey).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<ProxyKey> _proxyKeyEntityToProxyKey(ProxyKeyEntity keyEntity) async {
    return ProxyKey(
      id: keyEntity.id,
      name: keyEntity.name,
      localAlias: keyEntity.localAlias,
      privateKeyEncoded: await _decrypt(
        encryptionAlgorithm: keyEntity.encryptionAlgorithm,
        cipherText: keyEntity.encryptedPrivateKeyEncoded,
      ),
      privateKeySha256Thumbprint: keyEntity.privateKeySha256Thumbprint,
      publicKeyEncoded: keyEntity.publicKeyEncoded,
      publicKeySha256Thumbprint: keyEntity.publicKeySha256Thumbprint,
    );
  }

  Future<ProxyKeyEntity> _proxyKeyToProxyKeyEntity(ProxyKey key) async {
    return ProxyKeyEntity(
      id: key.id,
      name: key.name,
      localAlias: key.localAlias,
      encryptionAlgorithm: ENCRYPTION_ALGORITHM,
      encryptedPrivateKeyEncoded: await _encrypt(
        encryptionAlgorithm: ENCRYPTION_ALGORITHM,
        plainText: key.privateKeyEncoded,
      ),
      privateKeySha256Thumbprint: key.privateKeySha256Thumbprint,
      publicKeyEncoded: key.publicKeyEncoded,
      publicKeySha256Thumbprint: key.publicKeySha256Thumbprint,
      fcmToken: 'dummy', // Required for Querying
    );
  }

  // TODO: Revisit
  Key get _adjustedKey {
    String adjusted = passPhrase;
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

  Future<String> _encrypt({
    @required String encryptionAlgorithm,
    @required String plainText,
  }) async {
    final iv = IV.fromLength(16);
    Encrypter encrypter = _cipher(encryptionAlgorithm);
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  Future<String> _decrypt({
    @required String encryptionAlgorithm,
    @required String cipherText,
  }) async {
    final iv = IV.fromLength(16);
    Encrypter encrypter = _cipher(encryptionAlgorithm);
    return encrypter.decrypt64(cipherText, iv: iv);
  }

  static const String ENCRYPTION_ALGORITHM = 'AES/CTR/NoPadding';
}
