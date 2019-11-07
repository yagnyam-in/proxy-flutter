import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/withdrawal_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';

part 'withdrawal_event.g.dart';

@JsonSerializable()
class WithdrawalEvent extends EventEntity with ProxyUtils {
  @JsonKey(nullable: false)
  final WithdrawalStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final String destinationAccountNumber;

  @JsonKey(nullable: false)
  final String destinationAccountBank;

  String get withdrawalId => eventId;

  WithdrawalEvent({
    EventType eventType = EventType.Withdrawal, // Required for Json
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required String withdrawalId,
    @required bool completed,
    @required this.status,
    @required this.amount,
    @required this.destinationAccountNumber,
    @required this.destinationAccountBank,
  }) : super(
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          eventId: withdrawalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        ) {
    assert(eventType == EventType.Withdrawal);
  }

  WithdrawalEvent copy({
    WithdrawalStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
  }) {
    WithdrawalStatusEnum effectiveStatus = status ?? this.status;
    return WithdrawalEvent(
      proxyUniverse: this.proxyUniverse,
      withdrawalId: this.withdrawalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      amount: this.amount,
      status: effectiveStatus,
      destinationAccountNumber: this.destinationAccountNumber,
      destinationAccountBank: this.destinationAccountBank,
    );
  }

  factory WithdrawalEvent.fromWithdrawalEntity(WithdrawalEntity withdrawalEntity) => WithdrawalEvent(
        proxyUniverse: withdrawalEntity.proxyUniverse,
        withdrawalId: withdrawalEntity.withdrawalId,
        creationTime: withdrawalEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: withdrawalEntity.amount,
        status: withdrawalEntity.status,
        destinationAccountBank: withdrawalEntity.destinationAccountBank,
        destinationAccountNumber: withdrawalEntity.destinationAccountNumber,
        completed: withdrawalEntity.completed,
      );

  WithdrawalEvent copyFromWithdrawalEntity(WithdrawalEntity withdrawalEntity) {
    return copy(
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      completed: completed ?? this.completed,
      status: status ?? this.status,
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
