import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/deposit_event.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_authorization_event.dart';
import 'package:promo/banking/model/payment_encashment_event.dart';
import 'package:promo/banking/model/withdrawal_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';

import 'abstract_store.dart';

class EventStore extends AbstractStore<EventEntity> {
  EventStore(AppConfiguration appConfiguration) : super(appConfiguration);

  @override
  FromJson<EventEntity> get fromJson => _fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('events');
  }

  Stream<List<EventEntity>> subscribeForEvents({@required String proxyUniverse}) {
    print('subscribeForEvents($proxyUniverse)');
    Query query = rootCollection
        .where(EventEntity.PROXY_UNIVERSE, isEqualTo: proxyUniverse)
        .where(EventEntity.ACTIVE, isEqualTo: true)
        .orderBy('creationTime', descending: true);
    return query.snapshots().map(querySnapshotToEntityList);
  }

  static EventEntity _fromJson(Map<dynamic, dynamic> json) {
    print("Constructing Event of type ${json['eventType']}");
    switch (json[EventEntity.EVENT_TYPE]) {
      case 'Deposit':
        return DepositEvent.fromJson(json);
      case 'Withdrawal':
        return WithdrawalEvent.fromJson(json);
      case 'PaymentAuthorization':
        return PaymentAuthorizationEvent.fromJson(json);
      case 'PaymentEncashment':
        return PaymentEncashmentEvent.fromJson(json);
      default:
        return null;
    }
  }
}
