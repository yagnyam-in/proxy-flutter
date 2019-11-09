import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/banking/model/withdrawal_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:quiver/strings.dart';

import 'abstract_store.dart';

class WithdrawalStore extends AbstractStore<WithdrawalEntity> {
  final EventStore _eventStore;

  WithdrawalStore(AppConfiguration appConfiguration)
      : _eventStore = EventStore(appConfiguration),
        super(appConfiguration);

  @override
  FromJson<WithdrawalEntity> get fromJson => WithdrawalEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('withdrawals');
  }

  Future<WithdrawalEntity> fetch({
    @required String bankId,
    @required String withdrawalId,
  }) async {
    var query = rootCollection.where(WithdrawalEntity.WITHDRAWAL_ID, isEqualTo: withdrawalId);
    if (isNotBlank(bankId)) {
      query = query.where(WithdrawalEntity.BANK_ID, isEqualTo: bankId);
    }
    return firstResult(await query.getDocuments(), query);
  }

  Future<WithdrawalEntity> saveWithdrawal(WithdrawalEntity withdrawal, {Transaction transaction}) async {
    withdrawal = withInternalId(withdrawal);
    final event = _eventStore.withInternalId(WithdrawalEvent.fromWithdrawalEntity(withdrawal));
    withdrawal = withdrawal.copyWithEventInternalId(event.internalId);

    await Future.wait([
      super.save(withdrawal, transaction: transaction),
      _eventStore.save(event, transaction: transaction),
    ]);
    return withdrawal;
  }
}
