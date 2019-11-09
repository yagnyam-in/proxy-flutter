import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/deposit_entity.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';
import 'package:quiver/strings.dart';

part 'deposit_event.g.dart';

@JsonSerializable()
class DepositEvent extends EventEntity {
  @JsonKey(nullable: false)
  final DepositStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId destinationProxyAccountId;

  @JsonKey(nullable: false)
  final String depositLink;

  String get depositInternalId => actualEventInternalId;

  DepositEvent({
    EventType eventType = EventType.Deposit, // Required for Json
    @required String internalId,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required bool active,
    @required String depositInternalId,
    @required this.status,
    @required this.amount,
    @required this.destinationProxyAccountId,
    this.depositLink,
  }) : super(
          internalId: internalId,
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          actualEventInternalId: depositInternalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
          active: active,
        ) {
    assert(eventType == EventType.Deposit);
  }

  factory DepositEvent.fromDepositEntity(DepositEntity depositEntity) => DepositEvent(
        internalId: depositEntity.eventInternalId,
        proxyUniverse: depositEntity.proxyUniverse,
        depositInternalId: depositEntity.internalId,
        creationTime: depositEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: depositEntity.amount,
        status: depositEntity.status,
        destinationProxyAccountId: depositEntity.destinationProxyAccountId,
        completed: depositEntity.completed,
        active: true,
      );

  DepositEvent copyFromDepositEntity(DepositEntity depositEntity) {
    return copy(
      depositInternalId: depositEntity.internalId,
      lastUpdatedTime: depositEntity.lastUpdatedTime,
      completed: depositEntity.completed,
      depositLink: depositEntity.depositLink,
      status: depositEntity.status,
    );
  }

  DepositEvent copy({
    String depositInternalId,
    String depositLink,
    DepositStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
    bool active,
  }) {
    return DepositEvent(
      internalId: internalId,
      proxyUniverse: this.proxyUniverse,
      depositInternalId: depositInternalId ?? this.depositInternalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      active: active ?? this.active,
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
