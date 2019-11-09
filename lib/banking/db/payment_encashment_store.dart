import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/banking/model/payment_encashment_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:quiver/strings.dart';

import 'abstract_store.dart';

class PaymentEncashmentStore extends AbstractStore<PaymentEncashmentEntity> {
  final EventStore _eventStore;

  PaymentEncashmentStore(AppConfiguration appConfiguration)
      : _eventStore = EventStore(appConfiguration),
        super(appConfiguration);

  @override
  FromJson<PaymentEncashmentEntity> get fromJson => PaymentEncashmentEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('payment-encashments');
  }

  Future<PaymentEncashmentEntity> fetch({
    @required String payerBankId,
    @required String paymentAuthorizationId,
    @required String payeeBankId,
    @required String paymentEncashmentId,
  }) async {
    var query;
    if (isNotBlank(paymentEncashmentId)) {
      query = query != null
          ? query.where(PaymentEncashmentEntity.PAYMENT_ENCASHMENT_ID, isEqualTo: paymentEncashmentId)
          : rootCollection.where(PaymentEncashmentEntity.PAYMENT_ENCASHMENT_ID, isEqualTo: paymentEncashmentId);
    }
    if (isNotBlank(paymentAuthorizationId)) {
      query = query != null
          ? query.where(PaymentEncashmentEntity.PAYMENT_AUTHORIZATION_ID, isEqualTo: paymentAuthorizationId)
          : rootCollection.where(PaymentEncashmentEntity.PAYMENT_AUTHORIZATION_ID, isEqualTo: paymentAuthorizationId);
    }
    if (isNotBlank(payerBankId)) {
      query = query != null
          ? query.where(PaymentEncashmentEntity.PAYER_BANK_ID, isEqualTo: payerBankId)
          : rootCollection.where(PaymentEncashmentEntity.PAYER_BANK_ID, isEqualTo: payerBankId);
    }
    if (isNotBlank(payeeBankId)) {
      query = query != null
          ? query.where(PaymentEncashmentEntity.PAYEE_BANK_ID, isEqualTo: payeeBankId)
          : rootCollection.where(PaymentEncashmentEntity.PAYEE_BANK_ID, isEqualTo: payeeBankId);
    }
    return firstResult(await query.getDocuments(), query);
  }

  Future<PaymentEncashmentEntity> save(PaymentEncashmentEntity paymentEncashment, {Transaction transaction}) async {
    paymentEncashment = withInternalId(paymentEncashment);
    final event = _eventStore.withInternalId(PaymentEncashmentEvent.fromPaymentEncashmentEntity(paymentEncashment));
    paymentEncashment = paymentEncashment.copyWithEventInternalId(event.internalId);

    await Future.wait([
      super.save(paymentEncashment, transaction: transaction),
      _eventStore.save(event, transaction: transaction),
    ]);
    return paymentEncashment;
  }
}
