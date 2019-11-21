import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/abstract_store.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/banking/model/payment_authorization_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:quiver/strings.dart';

import 'cleanup_service.dart';

class PaymentAuthorizationStore extends AbstractStore<PaymentAuthorizationEntity> {
  final EventStore _eventStore;
  final CleanupService _cleanupService;

  PaymentAuthorizationStore(AppConfiguration appConfiguration)
      : _eventStore = EventStore(appConfiguration),
        _cleanupService = CleanupService(appConfiguration),
        super(appConfiguration);

  @override
  FromJson<PaymentAuthorizationEntity> get fromJson => PaymentAuthorizationEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('payment-authorizations');
  }

  Future<PaymentAuthorizationEntity> fetch({
    @required String bankId,
    @required String paymentAuthorizationId,
  }) async {
    var query = rootCollection.where(
      PaymentAuthorizationEntity.PAYMENT_AUTHORIZATION_ID,
      isEqualTo: paymentAuthorizationId,
    );
    if (isNotBlank(bankId)) {
      query = query.where(PaymentAuthorizationEntity.BANK_ID, isEqualTo: bankId);
    }
    return firstResult(await query.getDocuments(), query);
  }

  Future<PaymentAuthorizationEntity> save(PaymentAuthorizationEntity paymentAuthorization,
      {Transaction transaction}) async {
    paymentAuthorization = withInternalId(paymentAuthorization);
    final event =
    _eventStore.withInternalId(PaymentAuthorizationEvent.fromPaymentAuthorizationEntity(paymentAuthorization));
    paymentAuthorization = paymentAuthorization.copyWithEventInternalId(event.internalId);

    await Future.wait([
      super.save(paymentAuthorization, transaction: transaction),
      _eventStore.save(event, transaction: transaction),
      _cleanupService.onPaymentAuthorization(paymentAuthorization),
    ]);
    return paymentAuthorization;
  }
}
