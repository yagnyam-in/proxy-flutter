import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

part 'payment_encashment_event.g.dart';

@JsonSerializable()
class PaymentEncashmentEvent extends EventEntity with ProxyUtils {
  @JsonKey(nullable: false)
  final PaymentEncashmentStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payeeAccountId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  @JsonKey(nullable: false)
  final String paymentAuthorizationId;

  String get paymentEncashmentId => eventId;

  PaymentEncashmentEvent({
    EventType eventType = EventType.PaymentEncashment, // Required for Json
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required this.paymentAuthorizationId,
    @required String paymentEncashmentId,
    @required this.status,
    @required this.amount,
    @required this.payeeAccountId,
    @required this.paymentAuthorizationLink,
  }) : super(
          eventType: eventType,
          proxyUniverse: proxyUniverse,
          eventId: paymentEncashmentId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
        ) {
    assert(eventType == EventType.PaymentEncashment);
  }

  factory PaymentEncashmentEvent.fromPaymentEncashmentEntity(PaymentEncashmentEntity paymentEncashmentEntity) =>
      PaymentEncashmentEvent(
        proxyUniverse: paymentEncashmentEntity.proxyUniverse,
        paymentAuthorizationId: paymentEncashmentEntity.paymentAuthorizationId,
        paymentEncashmentId: paymentEncashmentEntity.paymentEncashmentId,
        creationTime: paymentEncashmentEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: paymentEncashmentEntity.amount,
        status: paymentEncashmentEntity.status,
        payeeAccountId: paymentEncashmentEntity.payeeAccountId,
        paymentAuthorizationLink: paymentEncashmentEntity.paymentAuthorizationLink,
        completed: paymentEncashmentEntity.completed,
      );

  PaymentEncashmentEvent copyFromPaymentEncashmentEntity(PaymentEncashmentEntity paymentEncashmentEntity) {
    return copy(
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      completed: completed ?? this.completed,
      status: status ?? this.status,
    );
  }

  PaymentEncashmentEvent copy({
    PaymentEncashmentStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
  }) {
    return PaymentEncashmentEvent(
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.paymentAuthorizationId,
      paymentEncashmentId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      amount: this.amount,
      payeeAccountId: this.payeeAccountId,
      paymentAuthorizationLink: this.paymentAuthorizationLink,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$PaymentEncashmentEventToJson(this);

  static PaymentEncashmentEvent fromJson(Map json) => _$PaymentEncashmentEventFromJson(json);

  String getTitle(ProxyLocalizations localizations) {
    return localizations.paymentEncashmentEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.paymentEncashmentEventSubTitle(payeeAccountId.accountId);
  }

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return PaymentEncashmentEntity.statusAsText(localizations, status);
  }

  IconData icon() {
    return Icons.file_download;
  }

  bool isCancellable() {
    return PaymentEncashmentEntity.cancelPossibleStatuses.contains(status);
  }
}
