import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class EventStore with ProxyUtils, FirestoreUtils {
  DocumentReference ref({
    @required String proxyUniverse,
    @required String eventId,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('events')
        .document(eventId);
  }

  final DocumentReference root;

  EventStore({
    @required this.root,
  }) {
    assert(root != null);
  }

  Future<EventEntity> fetchEvent({
    @required String proxyUniverse,
    @required String eventId,
  }) async {
    DocumentSnapshot snapshot = await ref(
      proxyUniverse: proxyUniverse,
      eventId: eventId,
    ).get();
    if (snapshot.exists) {
      return fromJson(snapshot.data);
    }
    return null;
  }

  Future<EventEntity> saveEvent(EventEntity event) async {
    await ref(
      proxyUniverse: event.proxyUniverse,
      eventId: event.eventId,
    ).setData(event.toJson());
    return event;
  }

  static EventEntity fromJson(Map<dynamic, dynamic> json) {
    switch (json["eventType"]) {
      case 'Deposit':
        return DepositEvent.fromJson(json);
      default:
        return null;
    }
  }
}
