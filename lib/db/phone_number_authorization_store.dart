import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/model/phone_number_authorization_entity.dart';
import 'package:proxy_flutter/services/enticement_service.dart';

class PhoneNumberAuthorizationStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  PhoneNumberAuthorizationStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference get allPhoneNumberAuthorizations => root.collection('phone-number-authorizations');

  CollectionReference get authorizedPhoneNumberAuthorizations => root.collection('phone-numbers-authorized');

  DocumentReference _refById(String authorizationId) {
    return allPhoneNumberAuthorizations.document(authorizationId);
  }

  DocumentReference _refByPhoneNumber(String phoneNumber) {
    return authorizedPhoneNumberAuthorizations.document(phoneNumber.toLowerCase());
  }

  DocumentReference _refByPhoneNumberAndProxyId(String phoneNumber, ProxyId proxyId) {
    return _refByPhoneNumber(phoneNumber).collection('proxies').document(proxyId.uniqueId);
  }

  Future<PhoneNumberAuthorizationEntity> fetchAuthorizationById(String authorizationId) async {
    DocumentSnapshot doc = await _refById(authorizationId).get();
    return _documentSnapshotToAuthorization(doc);
  }

  Future<PhoneNumberAuthorizationEntity> fetchActiveAuthorizationByPhoneNumber({
    @required String phoneNumber,
    @required ProxyId proxyId,
  }) async {
    DocumentSnapshot doc = await _refByPhoneNumberAndProxyId(phoneNumber, proxyId).get();
    PhoneNumberAuthorizationEntity authorization = _documentSnapshotToAuthorization(doc);
    if (authorization != null &&
        authorization.authorized &&
        authorization.validFrom.isBefore(DateTime.now()) &&
        authorization.validTill.isAfter(DateTime.now())) {
      return authorization;
    }
    return null;
  }

  PhoneNumberAuthorizationEntity _documentSnapshotToAuthorization(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return PhoneNumberAuthorizationEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  Stream<List<PhoneNumberAuthorizationEntity>> subscribeForAuthorizations() {
    return allPhoneNumberAuthorizations.snapshots().map(_querySnapshotToAuthorization);
  }

  Stream<PhoneNumberAuthorizationEntity> subscribeForAuthorization(String authorizationId) {
    return allPhoneNumberAuthorizations.document(authorizationId).snapshots().map(_documentSnapshotToAuthorization);
  }

  List<PhoneNumberAuthorizationEntity> _querySnapshotToAuthorization(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAuthorization).where((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<PhoneNumberAuthorizationEntity> saveAuthorization(PhoneNumberAuthorizationEntity authorization) async {
    await _refById(authorization.authorizationId).setData(authorization.toJson());
    if (authorization.authorized) {
      await _refByPhoneNumber(authorization.phoneNumber).setData({'lastUpdated': DateTime.now()});
      await _refByPhoneNumberAndProxyId(authorization.phoneNumber, authorization.proxyId)
          .setData(authorization.toJson());
      await EnticementService(appConfiguration).dismissEnticements(
        enticementId: Enticement.VERIFY_EMAIL,
      );
    }
    return authorization;
  }

  Future<void> deleteAuthorization(PhoneNumberAuthorizationEntity authorization) async {
    await Future.wait([
      _refById(authorization.authorizationId).delete(),
      _refByPhoneNumberAndProxyId(authorization.phoneNumber, authorization.proxyId).delete(),
    ]);
  }

  Future<Set<String>> authorizedPhoneNumbers(ProxyId proxyId) async {
    // print("Fetch Authorized Phone Numbers for $proxyId");
    final docs = await authorizedPhoneNumberAuthorizations.getDocuments();
    // print("Got ${docs.documents.length} documents");
    final phoneNumbers = await Future.wait(docs.documents.map((s) async {
      if (await _isPhoneNumberAuthorizedForProxy(s.documentID, proxyId)) {
        return s.documentID;
      } else {
        return null;
      }
    }));
    print("Authorized Phone Number: $phoneNumbers");
    return phoneNumbers.where((p) => p != null).toSet();
  }

  Future<bool> _isPhoneNumberAuthorizedForProxy(String phoneNumber, ProxyId proxyId) async {
    final snapshot = await _refByPhoneNumberAndProxyId(phoneNumber, proxyId).get();
    return snapshot != null && snapshot.exists;
  }
}
