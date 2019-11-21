import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';

part 'payment_authorization_event.g.dart';

@JsonSerializable()
class PaymentAuthorizationEvent extends EventEntity {
  @JsonKey(nullable: false)
  final PaymentAuthorizationStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payerAccountId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  String get paymentAuthorizationInternalId => actualEventInternalId;

  PaymentAuthorizationEvent({
    @required String internalId,
    EventType eventType = EventType.PaymentAuthorization, // Required for Json
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required bool active,
    @required String paymentAuthorizationInternalId,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.paymentAuthorizationLink,
  }) : super(
          internalId: internalId,
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          actualEventInternalId: paymentAuthorizationInternalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
    active: active,
        ) {
    assert(eventType == EventType.PaymentAuthorization);
  }

  factory PaymentAuthorizationEvent.fromPaymentAuthorizationEntity(
          PaymentAuthorizationEntity paymentAuthorizationEntity) =>
      PaymentAuthorizationEvent(
        internalId: paymentAuthorizationEntity.eventInternalId,
        proxyUniverse: paymentAuthorizationEntity.proxyUniverse,
        paymentAuthorizationInternalId: paymentAuthorizationEntity.internalId,
        creationTime: paymentAuthorizationEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: paymentAuthorizationEntity.amount,
        status: paymentAuthorizationEntity.status,
        payerAccountId: paymentAuthorizationEntity.payerAccountId,
        paymentAuthorizationLink: paymentAuthorizationEntity.paymentAuthorizationLink,
        completed: paymentAuthorizationEntity.completed,
        active: true,
      );

  PaymentAuthorizationEvent copyFromPaymentAuthorizationEntity(PaymentAuthorizationEntity paymentAuthorizationEntity) {
    return copy(
      paymentAuthorizationInternalId: paymentAuthorizationEntity.internalId,
      lastUpdatedTime: paymentAuthorizationEntity.lastUpdatedTime,
      completed: paymentAuthorizationEntity.completed,
      status: paymentAuthorizationEntity.status,
    );
  }

  PaymentAuthorizationEvent copy({
    String paymentAuthorizationInternalId,
    PaymentAuthorizationStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
    bool active,
  }) {
    return PaymentAuthorizationEvent(
      internalId: internalId,
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationInternalId: paymentAuthorizationInternalId ?? this.paymentAuthorizationInternalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      active: active ?? this.active,
      amount: this.amount,
      payerAccountId: this.payerAccountId,
      paymentAuthorizationLink: this.paymentAuthorizationLink,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$PaymentAuthorizationEventToJson(this);

  static PaymentAuthorizationEvent fromJson(Map json) => _$PaymentAuthorizationEventFromJson(json);

  String getTitle(ProxyLocalizations localizations) {
    return localizations.paymentAuthorizationEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.paymentAuthorizationEventSubTitle(payerAccountId.accountId);
  }

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return PaymentAuthorizationEntity.statusAsText(localizations, status);
  }

  IconData icon() {
    return Icons.file_download;
  }

  bool isCancellable() {
    return PaymentAuthorizationEntity.cancelPossibleStatuses.contains(status);
  }
}
