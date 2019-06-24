import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/contact_entity.dart';

class ContactStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  ContactStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference accountsRef() {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(appConfiguration.proxyUniverse)
        .collection('contacts');
  }

  DocumentReference ref(ProxyId proxyId) {
    return accountsRef().document(proxyId.id);
  }

  Stream<List<ContactEntity>> subscribeForContacts() {
    return accountsRef().snapshots().map(_querySnapshotToContacts);
  }

  Stream<ContactEntity> subscribeForContact(ProxyId proxyId) {
    return ref(proxyId).snapshots().map(_documentSnapshotToContact);
  }

  Future<ContactEntity> fetchContact(ProxyId proxyId) async {
    DocumentSnapshot doc = await ref(proxyId).get();
    return _documentSnapshotToContact(doc);
  }

  ContactEntity _documentSnapshotToContact(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return ContactEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<ContactEntity> _querySnapshotToContacts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents
          .map(_documentSnapshotToContact)
          .takeWhile((a) => a != null)
          .toList();
    } else {
      return [];
    }
  }

  Future<ContactEntity> saveContact(ContactEntity contact) async {
    assert(contact.proxyUniverse == appConfiguration.proxyUniverse);
    await ref(contact.proxyId).setData(contact.toJson());
    return contact;
  }

  Future<void> archiveContact(ContactEntity contact) {
    assert(contact.proxyUniverse == appConfiguration.proxyUniverse);
    return ref(contact.proxyId).delete();
  }
}
