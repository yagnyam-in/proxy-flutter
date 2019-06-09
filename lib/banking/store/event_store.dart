import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class EventStore with ProxyUtils, FirestoreUtils {

  CollectionReference eventsRef({
    @required String proxyUniverse,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('events');
  }

  DocumentReference ref({
    @required String proxyUniverse,
    @required String eventId,
  }) {
    return eventsRef(proxyUniverse: proxyUniverse)
        .document(eventId);
  }

  final FirebaseUser firebaseUser;
  final DocumentReference root;

  EventStore({
    @required this.firebaseUser,
  }) : root = FirestoreUtils.rootRef(firebaseUser) {
    assert(firebaseUser != null);
  }


  Stream<QuerySnapshot> fetchEvents({
    @required String proxyUniverse,
  }) {
    return eventsRef(proxyUniverse: proxyUniverse).snapshots();
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
