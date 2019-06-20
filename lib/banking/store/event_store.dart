import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class EventStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  EventStore(this.appConfiguration) : root = FirestoreUtils.rootRef(appConfiguration.firebaseUser);

  CollectionReference eventsRef({
    @required String proxyUniverse,
  }) {
    return root.collection(FirestoreUtils.PROXY_UNIVERSE_NODE).document(proxyUniverse).collection('events');
  }

  DocumentReference ref({
    @required String proxyUniverse,
    @required String eventId,
  }) {
    return eventsRef(proxyUniverse: proxyUniverse).document(eventId);
  }

  Stream<List<EventEntity>> subscribeForEvents() {
    return eventsRef(proxyUniverse: appConfiguration.proxyUniverse).snapshots().map(_querySnapshotToAccounts);
  }

  EventEntity _documentSnapshotToAccount(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return fromJson(snapshot.data);
    } else {
      return null;
    }
  }

  List<EventEntity> _querySnapshotToAccounts(QuerySnapshot snapshot) {
    if (snapshot.documents != null) {
      return snapshot.documents.map(_documentSnapshotToAccount).takeWhile((a) => a != null).toList();
    } else {
      return [];
    }
  }

  Future<EventEntity> saveEvent(EventEntity event) async {
    await ref(
      proxyUniverse: event.proxyUniverse,
      eventId: event.eventId,
    ).setData(event.toJson());
    return event;
  }

  Future<void> deleteEvent(EventEntity event) {
    return ref(
      proxyUniverse: event.proxyUniverse,
      eventId: event.eventId,
    ).delete();
  }

  static EventEntity fromJson(Map<dynamic, dynamic> json) {
    print("Constructing Event of type ${json['eventType']}");
    switch (json["eventType"]) {
      case 'Deposit':
        return DepositEvent.fromJson(json);
      case 'Withdrawal':
        return WithdrawalEvent.fromJson(json);
      case 'PaymentAuthorization':
        return PaymentAuthorizationEvent.fromJson(json);
      default:
        return null;
    }
  }
}
