import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/email_authorization_entity.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/services/enticement_service.dart';

class EmailAuthorizationStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  EmailAuthorizationStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference get allEmailAuthorizations => root.collection('email-authorizations');

  CollectionReference get authorizedEmailAuthorizations => root.collection('emails-authorized');

  DocumentReference _refById(String authorizationId) {
    return allEmailAuthorizations.document(authorizationId);
  }

  DocumentReference _refByEmail(String email) {
    return authorizedEmailAuthorizations.document(email.toLowerCase());
  }

  DocumentReference _refByEmailAndProxyId(String email, ProxyId proxyId) {
    return _refByEmail(email).collection('proxies').document(proxyId.uniqueId);
  }

  Future<EmailAuthorizationEntity> fetchAuthorizationById(String authorizationId) async {
    DocumentSnapshot doc = await _refById(authorizationId).get();
    return _documentSnapshotToAuthorization(doc);
  }

  Future<EmailAuthorizationEntity> fetchActiveAuthorizationByEmail({
    @required String email,
    @required ProxyId proxyId,
  }) async {
    DocumentSnapshot snapshot = await _refByEmailAndProxyId(email, proxyId).get();
    EmailAuthorizationEntity authorization = _documentSnapshotToAuthorization(snapshot);
    if (authorization != null &&
        authorization.authorized &&
        authorization.validFrom.isBefore(DateTime.now()) &&
        authorization.validTill.isAfter(DateTime.now())) {
      return authorization;
    }
    return null;
  }

  Stream<List<EmailAuthorizationEntity>> subscribeForAuthorizations() {
    return allEmailAuthorizations.snapshots().map(_querySnapshotToAuthorization);
  }

  Stream<EmailAuthorizationEntity> subscribeForAuthorization(String authorizationId) {
    print("subscribeForAuthorization($authorizationId)");
    return allEmailAuthorizations.document(authorizationId).snapshots().map(_documentSnapshotToAuthorization);
  }

  List<EmailAuthorizationEntity> _querySnapshotToAuthorization(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAuthorization).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  EmailAuthorizationEntity _documentSnapshotToAuthorization(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return EmailAuthorizationEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  Future<EmailAuthorizationEntity> saveAuthorization(EmailAuthorizationEntity authorization) async {
    await _refById(authorization.authorizationId).setData(authorization.toJson());
    if (authorization.authorized) {
      await _refByEmail(authorization.email).setData({'lastUpdated': DateTime.now()});
      await _refByEmailAndProxyId(authorization.email, authorization.proxyId).setData(authorization.toJson());
      await EnticementService(appConfiguration).dismissEnticements(
        enticementId: Enticement.VERIFY_EMAIL,
      );
    }
    return authorization;
  }

  Future<void> deleteAuthorization(EmailAuthorizationEntity authorization) async {
    await Future.wait([
      _refById(authorization.authorizationId).delete(),
      _refByEmailAndProxyId(authorization.email, authorization.proxyId).delete(),
    ]);
  }

  Future<Set<String>> authorizedEmails(ProxyId proxyId) async {
    // print("Fetch Authorized Emails for $proxyId");
    final docs = await authorizedEmailAuthorizations.getDocuments();
    // print("Got ${docs.documents.length} documents");
    final emails = await Future.wait(docs.documents.map((s) async {
      if (await _isEmailAuthorizedForProxy(s.documentID, proxyId)) {
        return s.documentID;
      } else {
        return null;
      }
    }));
    print("Authorized Emails: $emails");
    return emails.where((e) => e != null).toSet();
  }

  Future<bool> _isEmailAuthorizedForProxy(String email, ProxyId proxyId) async {
    final snapshot = await _refByEmailAndProxyId(email, proxyId).get();
    return snapshot != null && snapshot.exists;
  }
}
