import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

part 'payment_encashment_event.g.dart';

@JsonSerializable()
class PaymentEncashmentEvent extends EventEntity {
  @JsonKey(nullable: false)
  final PaymentEncashmentStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payeeAccountId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  String get paymentEncashmentInternalId => actualEventInternalId;

  PaymentEncashmentEvent({
    EventType eventType = EventType.PaymentEncashment, // Required for Json
    @required String internalId,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required bool completed,
    @required bool active,
    @required String paymentEncashmentInternalId,
    @required this.status,
    @required this.amount,
    @required this.payeeAccountId,
    @required this.paymentAuthorizationLink,
  }) : super(
          eventType: eventType,
          internalId: internalId,
          proxyUniverse: proxyUniverse,
          actualEventInternalId: paymentEncashmentInternalId,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          completed: completed,
    active: active,
        ) {
    assert(eventType == EventType.PaymentEncashment);
  }

  factory PaymentEncashmentEvent.fromPaymentEncashmentEntity(PaymentEncashmentEntity paymentEncashmentEntity) =>
      PaymentEncashmentEvent(
        internalId: paymentEncashmentEntity.eventInternalId,
        proxyUniverse: paymentEncashmentEntity.proxyUniverse,
        paymentEncashmentInternalId: paymentEncashmentEntity.internalId,
        creationTime: paymentEncashmentEntity.creationTime,
        lastUpdatedTime: DateTime.now(),
        amount: paymentEncashmentEntity.amount,
        status: paymentEncashmentEntity.status,
        payeeAccountId: paymentEncashmentEntity.payeeAccountId,
        paymentAuthorizationLink: paymentEncashmentEntity.paymentAuthorizationLink,
        completed: paymentEncashmentEntity.completed,
        active: true,
      );

  PaymentEncashmentEvent copyFromPaymentEncashmentEntity(PaymentEncashmentEntity paymentEncashmentEntity) {
    return copy(
      paymentEncashmentInternalId: paymentEncashmentEntity.internalId,
      lastUpdatedTime: paymentEncashmentEntity.lastUpdatedTime,
      completed: paymentEncashmentEntity.completed,
      status: paymentEncashmentEntity.status,
    );
  }

  PaymentEncashmentEvent copy({
    String paymentEncashmentInternalId,
    PaymentEncashmentStatusEnum status,
    DateTime lastUpdatedTime,
    bool completed,
    bool active,
  }) {
    return PaymentEncashmentEvent(
      internalId: internalId,
      proxyUniverse: this.proxyUniverse,
      paymentEncashmentInternalId: paymentEncashmentInternalId ?? this.paymentEncashmentInternalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: completed ?? this.completed,
      active: active ?? this.active,
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
