import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/model/deposit_entity.dart';
import 'package:promo/banking/model/deposit_event.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:quiver/strings.dart';

import 'abstract_store.dart';
import 'cleanup_service.dart';

class DepositStore extends AbstractStore<DepositEntity> {
  final EventStore _eventStore;
  final CleanupService _cleanupService;

  DepositStore(AppConfiguration appConfiguration)
      : _eventStore = EventStore(appConfiguration),
        _cleanupService = CleanupService(appConfiguration),
        super(appConfiguration);

  @override
  FromJson<DepositEntity> get fromJson => DepositEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return FirestoreUtils.accountRootRef(appConfiguration.accountId).collection('deposits');
  }

  Future<DepositEntity> fetch({
    @required String bankId,
    @required String depositId,
  }) async {
    var query = rootCollection.where(DepositEntity.DEPOSIT_ID, isEqualTo: depositId);
    if (isNotBlank(bankId)) {
      query = query.where(DepositEntity.BANK_ID, isEqualTo: bankId);
    }
    return firstResult(await query.getDocuments(), query);
  }

  @override
  Future<DepositEntity> save(DepositEntity deposit, {Transaction transaction}) async {
    deposit = withInternalId(deposit);
    final event = _eventStore.withInternalId(DepositEvent.fromDepositEntity(deposit));
    deposit = deposit.copyWithEventInternalId(event.internalId);

    await Future.wait([
      super.save(deposit, transaction: transaction),
      _eventStore.save(event, transaction: transaction),
      _cleanupService.onDeposit(deposit),
    ]);
    return deposit;
  }
}
