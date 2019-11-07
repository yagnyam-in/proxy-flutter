import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';

part 'payment_authorization_event.g.dart';

@JsonSerializable()
class PaymentAuthorizationEvent extends EventEntity with ProxyUtils {
  @JsonKey(nullable: false)
  final PaymentAuthorizationStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payerAccountId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  String get paymentAuthorizationId => eventId;

  PaymentAuthorizationEvent({
    EventType eventType = EventType.PaymentAuthorization, // Required for Json
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required String paymentAuthorizationId,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.paymentAuthorizationLink,
  }) : super(
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          eventId: paymentAuthorizationId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        ) {
    assert(eventType == EventType.PaymentAuthorization);
  }

  factory PaymentAuthorizationEvent.fromPaymentAuthorizationEntity(
          PaymentAuthorizationEntity paymentAuthorizationEntity) =>
      PaymentAuthorizationEvent(
        proxyUniverse: paymentAuthorizationEntity.proxyUniverse,
        paymentAuthorizationId: paymentAuthorizationEntity.paymentAuthorizationId,
        creationTime: paymentAuthorizationEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: paymentAuthorizationEntity.amount,
        status: paymentAuthorizationEntity.status,
        payerAccountId: paymentAuthorizationEntity.payerAccountId,
        paymentAuthorizationLink: paymentAuthorizationEntity.paymentAuthorizationLink,
        completed: paymentAuthorizationEntity.completed,
      );

  PaymentAuthorizationEvent copyFromPaymentAuthorizationEntity(PaymentAuthorizationEntity paymentAuthorizationEntity) {
    return copy(
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      completed: completed ?? this.completed,
      status: status ?? this.status,
    );
  }

  PaymentAuthorizationEvent copy({
    PaymentAuthorizationStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
  }) {
    return PaymentAuthorizationEvent(
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
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
