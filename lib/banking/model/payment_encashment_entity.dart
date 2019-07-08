import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

part 'payment_encashment_entity.g.dart';

@JsonSerializable()
class PaymentEncashmentEntity {
  static final Set<PaymentEncashmentStatusEnum> cancelPossibleStatuses = {
    PaymentEncashmentStatusEnum.Created,
    PaymentEncashmentStatusEnum.Registered,
  };

  @JsonKey(nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final String paymentAuthorizationId;

  @JsonKey(nullable: false)
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
  final ProxyAccountId payeeAccountId;

  @JsonKey(nullable: false)
  final ProxyId payeeProxyId;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  @JsonKey(nullable: true)
  final CipherText secretEncrypted;

  @JsonKey(nullable: true)
  final String email;

  @JsonKey(nullable: true)
  final String phone;

  @JsonKey(nullable: false, fromJson: PaymentEncashment.signedMessageFromJson)
  SignedMessage<PaymentEncashment> signedPaymentEncashment;

  PaymentEncashmentEntity({
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.paymentEncashmentId,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.status,
    @required this.amount,
    @required this.payeeAccountId,
    @required this.payeeProxyId,
    @required this.signedPaymentEncashment,
    @required this.paymentAuthorizationLink,
    @required this.completed,
    this.secretEncrypted,
    this.email,
    this.phone,
  });

  PaymentEncashmentEntity copy({
    int id,
    PaymentEncashmentStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    PaymentEncashmentStatusEnum effectiveStatus = status ?? this.status;
    return PaymentEncashmentEntity(
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.paymentAuthorizationId,
      paymentEncashmentId: this.paymentEncashmentId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      amount: this.amount,
      payeeAccountId: this.payeeAccountId,
      payeeProxyId: this.payeeProxyId,
      signedPaymentEncashment: this.signedPaymentEncashment,
      status: effectiveStatus,
      paymentAuthorizationLink: this.paymentAuthorizationLink,
      completed: isCompleteStatus(effectiveStatus),
      secretEncrypted: this.secretEncrypted,
      email: this.email,
      phone: this.phone,
    );
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
        return localizations.processedStatus;
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

  Map<String, dynamic> toJson() => _$PaymentEncashmentEntityToJson(this);

  static PaymentEncashmentEntity fromJson(Map json) => _$PaymentEncashmentEntityFromJson(json);

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
