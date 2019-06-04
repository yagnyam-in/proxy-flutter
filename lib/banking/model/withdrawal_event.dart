import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_messages/banking.dart';

class WithdrawalEvent extends EventEntity with ProxyUtils {
  final WithdrawalStatusEnum status;
  final Amount amount;
  final String destinationAccountNumber;
  final String destinationAccountBank;

  String get withdrawalId => eventId;

  WithdrawalEvent({
    int id,
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
          id: id,
          eventType: EventType.Withdraw,
          proxyUniverse: proxyUniverse,
          eventId: withdrawalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        );

  WithdrawalEvent copy({
    int id,
    WithdrawalStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
  }) {
    WithdrawalStatusEnum effectiveStatus = status ?? this.status;
    return WithdrawalEvent(
      id: id ?? this.id,
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


  @override
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = super.toRow();
    row[EventEntity.WITHDRAWAL_STATUS] = WithdrawalEntity.withdrawalStatusToString(status);
    row[EventEntity.WITHDRAWAL_AMOUNT_CURRENCY] = amount.currency;
    row[EventEntity.WITHDRAWAL_AMOUNT_VALUE] = amount.value;
    row[EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_NUMBER] = destinationAccountNumber;
    row[EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_BANK] = destinationAccountBank;
    return row;
  }

  WithdrawalEvent.fromRow(Map<dynamic, dynamic> row)
      : amount = Amount(row[EventEntity.WITHDRAWAL_AMOUNT_CURRENCY],
      row[EventEntity.WITHDRAWAL_AMOUNT_VALUE]),
        destinationAccountNumber = row[EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_NUMBER],
        destinationAccountBank = row[EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_BANK],
        status = WithdrawalEntity.stringToWithdrawalStatus(
          row[EventEntity.WITHDRAWAL_STATUS],
          orElse: WithdrawalStatusEnum.Registered,
        ),
        super.fromRow(row);



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

  String getTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventSubTitle(destinationAccountNumber);
  }

  String getAmountText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatus(ProxyLocalizations localizations) {
    switch (status) {
      case WithdrawalStatusEnum.Registered:
        return localizations.registered;
      case WithdrawalStatusEnum.Rejected:
        return localizations.rejected;
      case WithdrawalStatusEnum.InTransit:
        return localizations.inTransit;
      case WithdrawalStatusEnum.Completed:
        return localizations.completed;
      case WithdrawalStatusEnum.FailedInTransit:
        return localizations.failedInTransit;
      case WithdrawalStatusEnum.FailedCompleted:
        return localizations.failedCompleted;
      default:
        print("Unhandled Event state: $status");
        return localizations.inTransit;
    }
  }

  IconData icon() {
    return Icons.file_upload;
  }

  bool isCancellable() {
    return WithdrawalEntity.cancellableStatuses.contains(status);
  }
}
