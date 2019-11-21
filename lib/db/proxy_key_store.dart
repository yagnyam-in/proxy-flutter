import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:promo/model/account_entity.dart';
import 'package:promo/model/proxy_key_entity.dart';

class ProxyKeyStore with ProxyUtils, FirestoreUtils {
  final AccountEntity account;
  final String passPhrase;
  final SymmetricKeyEncryptionService encryptionService = SymmetricKeyEncryptionService();

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

  Future<List<ProxyKey>> fetchProxyKeys({Set<ProxyId> exclusion}) async {
    QuerySnapshot querySnapshot = await _proxiesRef().getDocuments();
    List<ProxyKeyEntity> entities =
        _querySnapshotToProxyKeys(querySnapshot).where((e) => !exclusion.contains(e.id)).toList();
    return Future.wait(entities.map(_proxyKeyEntityToProxyKey).toList());
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
      privateKeyEncoded: await encryptionService.decrypt(
        cipherText: keyEntity.privateKeyEncodedEncrypted,
        key: passPhrase,
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
      privateKeyEncodedEncrypted: await encryptionService.encrypt(
        encryptionAlgorithm: SymmetricKeyEncryptionService.ENCRYPTION_ALGORITHM,
        plainText: key.privateKeyEncoded,
        key: passPhrase,
      ),
      privateKeySha256Thumbprint: key.privateKeySha256Thumbprint,
      publicKeyEncoded: key.publicKeyEncoded,
      publicKeySha256Thumbprint: key.publicKeySha256Thumbprint,
    );
  }
}
