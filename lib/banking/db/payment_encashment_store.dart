import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/db/event_store.dart';
import 'package:proxy_flutter/banking/model/payment_encashment_entity.dart';
import 'package:proxy_flutter/banking/model/payment_encashment_event.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

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
      return _documentSnapshotToProxyKey(snapshot);
    } else if (paymentAuthorizationId != null) {
      QuerySnapshot docs = await _paymentEncshmentsRef(proxyUniverse: proxyUniverse)
          .where("paymentAuthorizationId", isEqualTo: paymentAuthorizationId)
          .getDocuments();
      if (docs.documents != null && docs.documents.isNotEmpty) {
        return _documentSnapshotToProxyKey(docs.documents.first);
      }
    }
    return null;
  }

  Stream<PaymentEncashmentEntity> subscribeForPaymentEncashment({
    @required String proxyUniverse,
    @required String paymentEncashmentId,
  }) {
    return _ref(
      proxyUniverse: proxyUniverse,
      paymentEncashmentId: paymentEncashmentId,
    ).snapshots().map(_documentSnapshotToProxyKey);
  }

  Future<PaymentEncashmentEntity> savePaymentEncashment(PaymentEncashmentEntity paymentEncashment) async {
    await _ref(
      proxyUniverse: paymentEncashment.proxyUniverse,
      paymentEncashmentId: paymentEncashment.paymentEncashmentId,
    ).setData(paymentEncashment.toJson());
    await _eventStore.saveEvent(PaymentEncashmentEvent.fromPaymentEncashmentEntity(paymentEncashment));
    return paymentEncashment;
  }

  PaymentEncashmentEntity _documentSnapshotToProxyKey(DocumentSnapshot snapshot) {
    if (snapshot == null || !snapshot.exists) {
      return null;
    }
    return PaymentEncashmentEntity.fromJson(snapshot.data);
  }
}
