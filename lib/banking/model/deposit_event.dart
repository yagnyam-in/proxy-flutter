import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_messages/banking.dart';

class DepositEvent extends EventEntity with ProxyUtils {
  final DepositStatusEnum status;
  final Amount amount;
  final ProxyAccountId destinationProxyAccountId;
  final String depositLink;

  String get depositId => eventId;

  DepositEvent({
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required String depositId,
    @required this.status,
    @required this.amount,
    @required this.destinationProxyAccountId,
    this.depositLink,
  }) : super(
          id: id,
          eventType: EventType.Deposit,
          proxyUniverse: proxyUniverse,
          eventId: depositId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        );

  @override
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = super.toRow();
    row[EventEntity.DEPOSIT_STATUS] = DepositEntity.depositStatusToString(status);
    row[EventEntity.DEPOSIT_AMOUNT_CURRENCY] = amount.currency;
    row[EventEntity.DEPOSIT_AMOUNT_VALUE] = amount.value;
    row[EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_ID] =
        destinationProxyAccountId.accountId;
    row[EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_BANK_ID] =
        destinationProxyAccountId.bankId;
    row[EventEntity.DEPOSIT_LINK] = depositLink;
    return row;
  }

  DepositEvent.fromRow(Map<dynamic, dynamic> row)
      : amount = Amount(row[EventEntity.DEPOSIT_AMOUNT_CURRENCY],
            row[EventEntity.DEPOSIT_AMOUNT_VALUE]),
        destinationProxyAccountId = ProxyAccountId(
            accountId: row[EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_ID],
            bankId: row[EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_BANK_ID],
            proxyUniverse: row[EventEntity.PROXY_UNIVERSE]),
        depositLink = row[EventEntity.DEPOSIT_LINK],
        status = DepositEntity.stringToDepositStatus(
          row[EventEntity.DEPOSIT_STATUS],
          orElse: DepositStatusEnum.Registered,
        ),
        super.fromRow(row);

  factory DepositEvent.fromDepositEntity(DepositEntity depositEntity) => DepositEvent(
    proxyUniverse: depositEntity.proxyUniverse,
    depositId: depositEntity.depositId,
    creationTime: depositEntity.creationTime,
    lastUpdatedTime: DateTime.now(),
    amount: depositEntity.amount,
    status: depositEntity.status,
    destinationProxyAccountId: depositEntity.destinationProxyAccountId,
    completed: depositEntity.completed,
  );

  DepositEvent copyFromDepositEntity(DepositEntity depositEntity) {
    return copy(
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      completed: completed ?? this.completed,
      depositLink: depositLink ?? this.depositLink,
      status: status ?? this.status,
    );
  }


  DepositEvent copy({
    int id,
    String depositLink,
    DepositStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
  }) {
    return DepositEvent(
      id: id ?? this.id,
      proxyUniverse: this.proxyUniverse,
      depositId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      amount: this.amount,
      destinationProxyAccountId: this.destinationProxyAccountId,
      depositLink: depositLink ?? this.depositLink,
      status: status ?? this.status,
    );
  }

  String getTitle(ProxyLocalizations localizations) {
    return localizations.depositEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations
        .depositEventSubTitle(destinationProxyAccountId.accountId);
  }

  String getAmountText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatus(ProxyLocalizations localizations) {
    return DepositEntity.statusDisplayMessage(localizations, status);
  }

  IconData icon() {
    return Icons.file_download;
  }

  bool isCancellable() {
    return DepositEntity.cancellableStatuses.contains(status);
  }

  bool isDepositPossible() {
    return DepositEntity.depositPossibleStatuses.contains(status) &&
        isNotEmpty(depositLink);
  }
}
