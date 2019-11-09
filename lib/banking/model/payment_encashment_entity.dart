import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/localizations.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

import 'abstract_entity.dart';

part 'payment_encashment_entity.g.dart';

@JsonSerializable()
class PaymentEncashmentEntity extends AbstractEntity<PaymentEncashmentEntity> with ProxyUtils {
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const PAYMENT_AUTHORIZATION_ID = "paymentAuthorizationId";
  static const PAYMENT_ENCASHMENT_ID = "paymentEncashmentId";
  static const PAYER_BANK_ID = "payerBankId";
  static const PAYEE_BANK_ID = "payeeBankId";

  static final Set<PaymentEncashmentStatusEnum> cancelPossibleStatuses = {
    PaymentEncashmentStatusEnum.Created,
    PaymentEncashmentStatusEnum.Registered,
  };

  @JsonKey(nullable: false)
  String internalId;

  @JsonKey(nullable: false)
  String eventInternalId;

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(name: PAYER_BANK_ID, nullable: false)
  final String payerBankId;

  @JsonKey(name: PAYMENT_AUTHORIZATION_ID, nullable: false)
  final String paymentAuthorizationId;

  @JsonKey(name: PAYEE_BANK_ID, nullable: false)
  final String payeeBankId;

  @JsonKey(name: PAYMENT_ENCASHMENT_ID, nullable: false)
  final String paymentEncashmentId;

  @JsonKey(nullable: false)
  final DateTime creationTime;

  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;

  @JsonKey(nullable: false)
  final PaymentEncashmentStatusEnum status;

  @JsonKey(nullable: false)
  final bool completed;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payerAccountId;

  @JsonKey(nullable: false)
  final ProxyAccountId payeeAccountId;

  @JsonKey(nullable: false)
  final ProxyId payeeProxyId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  @JsonKey(nullable: true)
  final CipherText secretEncrypted;

  // Don't store this
  @JsonKey(ignore: true)
  final String secret;

  @JsonKey(nullable: true)
  final String email;

  @JsonKey(nullable: true)
  final String phone;

  @JsonKey(nullable: false, fromJson: PaymentEncashment.signedMessageFromJson)
  SignedMessage<PaymentEncashment> signedPaymentEncashment;

  PaymentEncashmentEntity({
    this.internalId,
    this.eventInternalId,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.paymentEncashmentId,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.payeeAccountId,
    @required this.payeeProxyId,
    @required this.signedPaymentEncashment,
    @required this.paymentAuthorizationLink,
    @required this.completed,
    this.secret,
    this.secretEncrypted,
    this.email,
    this.phone,
    String payerBankId,
    String payeeBankId,
  })  : payerBankId = payerAccountId?.bankId,
        payeeBankId = payeeAccountId?.bankId {
    assert(payerBankId == null || this.payerBankId == payerBankId);
    assert(payeeBankId == null || this.payeeBankId == payeeBankId);
  }

  PaymentEncashmentEntity copy({
    PaymentEncashmentStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    PaymentEncashmentStatusEnum effectiveStatus = status ?? this.status;
    return PaymentEncashmentEntity(
      internalId: this.internalId,
      eventInternalId: this.eventInternalId,
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.paymentAuthorizationId,
      paymentEncashmentId: this.paymentEncashmentId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      amount: this.amount,
      payeeAccountId: this.payeeAccountId,
      payeeProxyId: this.payeeProxyId,
      payerAccountId: this.payerAccountId,
      signedPaymentEncashment: this.signedPaymentEncashment,
      status: effectiveStatus,
      paymentAuthorizationLink: this.paymentAuthorizationLink,
      completed: isCompleteStatus(effectiveStatus),
      secret: this.secret,
      secretEncrypted: this.secretEncrypted,
      email: this.email,
      phone: this.phone,
    );
  }

  @override
  PaymentEncashmentEntity copyWithInternalId(String id) {
    this.internalId = id;
    return this;
  }

  PaymentEncashmentEntity copyWithEventInternalId(String eventId) {
    this.eventInternalId = eventId;
    return this;
  }

  static bool isCompleteStatus(PaymentEncashmentStatusEnum status) {
    return status == PaymentEncashmentStatusEnum.Processed;
  }

  static String statusAsText(ProxyLocalizations localizations, PaymentEncashmentStatusEnum status) {
    switch (status) {
      case PaymentEncashmentStatusEnum.Registered:
        return localizations.registered;
      case PaymentEncashmentStatusEnum.Rejected:
        return localizations.rejected;
      case PaymentEncashmentStatusEnum.CancelledByPayer:
        return localizations.cancelledStatus;
      case PaymentEncashmentStatusEnum.CancelledByPayee:
        return localizations.cancelledStatus;
      case PaymentEncashmentStatusEnum.InProcess:
        return localizations.inProcess;
      case PaymentEncashmentStatusEnum.Processed:
        return localizations.paymentEncashedStatus;
      case PaymentEncashmentStatusEnum.InsufficientFunds:
        return localizations.insufficientFundsStatus;
      case PaymentEncashmentStatusEnum.Expired:
        return localizations.expiredStatus;
      case PaymentEncashmentStatusEnum.Error:
        return localizations.errorStatus;
      case PaymentEncashmentStatusEnum.Created:
        return localizations.created;
      default:
        print("Unhandled Event state: $status");
        return localizations.inTransit;
    }
  }

  @override
  Map<String, dynamic> toJson() => _$PaymentEncashmentEntityToJson(this);

  static PaymentEncashmentEntity fromJson(Map json) => _$PaymentEncashmentEntityFromJson(json);

  @override
  String toString() {
    return "$runtimeType(internalId: $internalId, paymentEncashmentId: $paymentEncashmentId, completed: $completed)";
  }

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return statusAsText(localizations, status);
  }

  IconData get icon {
    return Icons.file_download;
  }

  bool get isCancelPossible {
    return cancelPossibleStatuses.contains(status);
  }
}
