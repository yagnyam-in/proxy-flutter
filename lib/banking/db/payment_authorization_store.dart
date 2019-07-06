import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/db/event_store.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_event.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';

class PaymentAuthorizationStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;
  final EventStore _eventStore;

  PaymentAuthorizationStore(this.appConfiguration)
      : root = FirestoreUtils.accountRootRef(appConfiguration.accountId),
        _eventStore = EventStore(appConfiguration);

  DocumentReference ref({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('paymentAuthorizations')
        .document(paymentAuthorizationId);
  }

  Future<PaymentAuthorizationEntity> fetchPaymentAuthorization({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) async {
    DocumentSnapshot snapshot = await ref(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    ).get();
    return _documentSnapshotToProxyKey(snapshot);
  }

  Stream<PaymentAuthorizationEntity> subscribeForPaymentAuthorization({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) {
    return ref(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    ).snapshots().map(_documentSnapshotToProxyKey);
  }

  Future<PaymentAuthorizationEntity> savePaymentAuthorization(PaymentAuthorizationEntity paymentAuthorization) async {
    await ref(
      proxyUniverse: paymentAuthorization.proxyUniverse,
      paymentAuthorizationId: paymentAuthorization.paymentAuthorizationId,
    ).setData(paymentAuthorization.toJson());
    await _eventStore.saveEvent(PaymentAuthorizationEvent.fromPaymentAuthorizationEntity(paymentAuthorization));
    return paymentAuthorization;
  }

  PaymentAuthorizationEntity _documentSnapshotToProxyKey(DocumentSnapshot snapshot) {
    if (snapshot == null || !snapshot.exists) {
      return null;
    }
    return PaymentAuthorizationEntity.fromJson(snapshot.data);
  }
}
