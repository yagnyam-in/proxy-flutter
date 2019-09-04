import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/contact_entity.dart';

class ContactStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  ContactStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference get _contactsRef {
    return root.collection('contacts');
  }

  DocumentReference _ref(String id) {
    return _contactsRef.document(id);
  }

  Stream<List<ContactEntity>> subscribeForContacts() {
    return _contactsRef.snapshots().map(_querySnapshotToContacts);
  }

  Future<ContactEntity> fetchContactById(String id) async {
    DocumentSnapshot doc = await _ref(id).get();
    return _documentSnapshotToContact(doc);
  }

  Future<List<ContactEntity>> fetchContactByProxyId(ProxyId proxyId) async {
    if (isNotEmpty(proxyId?.id)) {
      Query query = _contactsRef.where('proxyId.id', isEqualTo: proxyId.id);
      final querySnapshots = await query.getDocuments();
      return _querySnapshotToContacts(querySnapshots).where((c) => c.proxyId == proxyId).toList();
    }
    return [];
  }

  Future<List<ContactEntity>> fetchContacts({
    @required String phoneNumber,
    @required String email,
  }) async {
    if (isNotEmpty(phoneNumber)) {
      Query query = _contactsRef.where('phoneNumber', isEqualTo: phoneNumber);
      final querySnapshots = await query.getDocuments();
      List<ContactEntity> results = _querySnapshotToContacts(querySnapshots);
      if (results.isNotEmpty) {
        return results;
      }
    }
    if (isNotEmpty(email)) {
      Query query = _contactsRef.where('email', isEqualTo: email.toLowerCase());
      final querySnapshots = await query.getDocuments();
      List<ContactEntity> results = _querySnapshotToContacts(querySnapshots);
      if (results.isNotEmpty) {
        return results;
      }
    }
    return [];
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
      return snapshot.documents.map(_documentSnapshotToContact).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<ContactEntity> saveContact(ContactEntity contact) async {
    await _ref(contact.id).setData(contact.toJson());
    return contact;
  }

  Future<void> archiveContact(ContactEntity contact) {
    return _ref(contact.id).delete();
  }
}
