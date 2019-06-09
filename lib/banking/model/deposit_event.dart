import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_messages/banking.dart';

part 'deposit_event.g.dart';

@JsonSerializable()
class DepositEvent extends EventEntity with ProxyUtils {
  @JsonKey(nullable: false)
  final DepositStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId destinationProxyAccountId;

  @JsonKey(nullable: false)
  final String depositLink;

  String get depositId => eventId;

  DepositEvent({
    EventType eventType = EventType.Deposit, // Required for Json
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
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          eventId: depositId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        ) {
    assert(eventType == EventType.Deposit);
  }

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

  @override
  Map<String, dynamic> toJson() => _$DepositEventToJson(this);

  static DepositEvent fromJson(Map json) => _$DepositEventFromJson(json);

  String getTitle(ProxyLocalizations localizations) {
    return localizations.depositEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.depositEventSubTitle(destinationProxyAccountId.accountId);
  }

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return DepositEntity.statusAsText(localizations, status);
  }

  IconData icon() {
    return Icons.file_download;
  }

  bool isCancellable() {
    return DepositEntity.cancelPossibleStatuses.contains(status);
  }

  bool isDepositPossible() {
    return DepositEntity.depositPossibleStatuses.contains(status) && isNotEmpty(depositLink);
  }
}
