import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';

part 'withdrawal_event.g.dart';

@JsonSerializable()
class WithdrawalEvent extends EventEntity {
  @JsonKey(nullable: false)
  final WithdrawalStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final String destinationAccountNumber;

  @JsonKey(nullable: false)
  final String destinationAccountBank;

  String get withdrawalInternalId => actualEventInternalId;

  WithdrawalEvent({
    EventType eventType = EventType.Withdrawal, // Required for Json
    @required String internalId,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required String withdrawalInternalId,
    @required bool completed,
    @required bool active,
    @required this.status,
    @required this.amount,
    @required this.destinationAccountNumber,
    @required this.destinationAccountBank,
  }) : super(
          internalId: internalId,
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          actualEventInternalId: withdrawalInternalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
          active: active,
        ) {
    assert(eventType == EventType.Withdrawal);
  }

  WithdrawalEvent copy({
    String withdrawalInternalId,
    WithdrawalStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
    bool active,
  }) {
    WithdrawalStatusEnum effectiveStatus = status ?? this.status;
    return WithdrawalEvent(
      internalId: internalId,
      proxyUniverse: this.proxyUniverse,
      withdrawalInternalId: withdrawalInternalId ?? this.withdrawalInternalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      amount: this.amount,
      status: effectiveStatus,
      destinationAccountNumber: this.destinationAccountNumber,
      destinationAccountBank: this.destinationAccountBank,
      active: active ?? this.active,
    );
  }

  factory WithdrawalEvent.fromWithdrawalEntity(WithdrawalEntity withdrawalEntity) => WithdrawalEvent(
        internalId: withdrawalEntity.eventInternalId,
        proxyUniverse: withdrawalEntity.proxyUniverse,
        withdrawalInternalId: withdrawalEntity.internalId,
        creationTime: withdrawalEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: withdrawalEntity.amount,
        status: withdrawalEntity.status,
        destinationAccountBank: withdrawalEntity.destinationAccountBank,
        destinationAccountNumber: withdrawalEntity.destinationAccountNumber,
        completed: withdrawalEntity.completed,
        active: true,
      );

  WithdrawalEvent copyFromWithdrawalEntity(WithdrawalEntity withdrawalEntity) {
    return copy(
      withdrawalInternalId: withdrawalEntity.internalId,
      lastUpdatedTime: withdrawalEntity.lastUpdatedTime,
      completed: withdrawalEntity.completed,
      status: withdrawalEntity.status,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$WithdrawalEventToJson(this);

  static WithdrawalEvent fromJson(Map json) => _$WithdrawalEventFromJson(json);

  @override
  String getTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventTitle;
  }

  @override
  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventSubTitle(destinationAccountNumber);
  }

  @override
  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  @override
  String getStatusAsText(ProxyLocalizations localizations) {
    return WithdrawalEntity.statusAsText(localizations, status);
  }

  IconData icon() {
    return Icons.file_upload;
  }

  bool isCancellable() {
    return WithdrawalEntity.cancellableStatuses.contains(status);
  }
}
