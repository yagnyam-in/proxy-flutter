import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/banking/model/payment_encashment_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';

class PaymentEncashmentStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final EventStore _eventStore;

  PaymentEncashmentStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId),
        _eventStore = EventStore(appConfiguration);

  CollectionReference _paymentEncshmentsRef({
    @required String proxyUniverse,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('payment-encashments');
  }

  DocumentReference _ref({
    @required String proxyUniverse,
    @required String paymentEncashmentId,
  }) {
    return _paymentEncshmentsRef(proxyUniverse: proxyUniverse).document(paymentEncashmentId);
  }

  Future<PaymentEncashmentEntity> fetchPaymentEncashment({
    @required String proxyUniverse,
    @required String paymentEncashmentId,
    @required String paymentAuthorizationId,
  }) async {
    if (paymentEncashmentId != null) {
      DocumentSnapshot snapshot = await _ref(
        proxyUniverse: proxyUniverse,
        paymentEncashmentId: paymentEncashmentId,
      ).get();
      return _documentSnapshotToEntity(snapshot);
    } else if (paymentAuthorizationId != null) {
      QuerySnapshot snapshot = await _paymentEncshmentsRef(proxyUniverse: proxyUniverse)
          .where("paymentAuthorizationId", isEqualTo: paymentAuthorizationId)
          .getDocuments();
      return _querySnapshotToFirstEntity(snapshot);
    }
    return null;
  }

  Stream<PaymentEncashmentEntity> subscribeForPaymentEncashment({
    @required String proxyUniverse,
    @required String paymentEncashmentId,
    @required String paymentAuthorizationId,
  }) {
    if (paymentEncashmentId != null) {
      return _ref(
        proxyUniverse: proxyUniverse,
        paymentEncashmentId: paymentEncashmentId,
      ).snapshots().map(_documentSnapshotToEntity);
    } else if (paymentAuthorizationId != null) {
      return _paymentEncshmentsRef(proxyUniverse: proxyUniverse)
          .where("paymentAuthorizationId", isEqualTo: paymentAuthorizationId)
          .snapshots()
          .map(_querySnapshotToFirstEntity);
    }
    return Stream.empty();
  }

  Future<PaymentEncashmentEntity> savePaymentEncashment(PaymentEncashmentEntity paymentEncashment) async {
    await _ref(
      proxyUniverse: paymentEncashment.proxyUniverse,
      paymentEncashmentId: paymentEncashment.paymentEncashmentId,
    ).setData(paymentEncashment.toJson());
    await _eventStore.saveEvent(PaymentEncashmentEvent.fromPaymentEncashmentEntity(paymentEncashment));
    return paymentEncashment;
  }

  PaymentEncashmentEntity _querySnapshotToFirstEntity(QuerySnapshot snapshot) {
    if (snapshot.documents != null && snapshot.documents.isNotEmpty) {
      return _documentSnapshotToEntity(snapshot.documents.first);
    }
    return null;
  }

  PaymentEncashmentEntity _documentSnapshotToEntity(DocumentSnapshot snapshot) {
    if (snapshot == null || !snapshot.exists) {
      return null;
    }
    return PaymentEncashmentEntity.fromJson(snapshot.data);
  }
}
