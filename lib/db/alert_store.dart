import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/services/alert_factory.dart';

class AlertStore with FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  AlertStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference _alertsRef() {
    return root.collection('devices').document(appConfiguration.deviceId).collection('alerts');
  }

  Future<void> deleteAlert(String alertRef) {
    return _alertsRef().document(alertRef).delete();
  }

  Future<Map<String, Alert>> fetchPendingAlerts() async {
    print('fetchPendingAlerts()');
    final documents = await _alertsRef().limit(8).getDocuments();
    return _querySnapshotToAlerts(documents);
  }

  Map<String, Alert> _querySnapshotToAlerts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      Map<String, Alert> alerts = {};
      snapshot.documents.map(_documentSnapshotToAlert).where((a) => a != null).forEach((a) => alerts.addAll(a));
      return alerts;
    } else {
      return {};
    }
  }

  Map<String, Alert> _documentSnapshotToAlert(DocumentSnapshot snapshot) {
    if (snapshot == null || !snapshot.exists) {
      return {};
    }
    Alert alert = AlertFactory.createAlert(snapshot.data);
    // Possible if Alert type is not known
    if (alert == null) {
      return {};
    }
    return {snapshot.documentID: alert};
  }
}
