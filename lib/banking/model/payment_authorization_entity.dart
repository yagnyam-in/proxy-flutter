import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';

part 'payment_authorization_entity.g.dart';

@JsonSerializable()
class PaymentAuthorizationEntity {
  static final Set<PaymentAuthorizationStatusEnum> cancelPossibleStatuses = {
    PaymentAuthorizationStatusEnum.Registered,
  };

  @JsonKey(nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final String paymentAuthorizationId;

  @JsonKey(nullable: false)
  final DateTime creationTime;

  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;

  @JsonKey(nullable: false)
  final PaymentAuthorizationStatusEnum status;

  @JsonKey(nullable: false)
  final bool completed;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payerAccountId;

  @JsonKey(nullable: false)
  final ProxyId payerProxyId;

  @JsonKey(nullable: false)
  final List<PaymentAuthorizationPayeeEntity> payees;

  @JsonKey(nullable: false)
  final String paymentAuthorizationLink;

  @JsonKey(nullable: false, fromJson: PaymentAuthorization.signedMessageFromJson)
  SignedMessage<PaymentAuthorization> signedPaymentAuthorization;

  PaymentAuthorizationEntity({
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.payerProxyId,
    @required this.signedPaymentAuthorization,
    @required this.paymentAuthorizationLink,
    @required this.payees,
    @required this.completed,
  });

  PaymentAuthorizationEntity copy({
    int id,
    PaymentAuthorizationStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    PaymentAuthorizationStatusEnum effectiveStatus = status ?? this.status;
    return PaymentAuthorizationEntity(
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.paymentAuthorizationId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      amount: this.amount,
      payerAccountId: this.payerAccountId,
      payerProxyId: this.payerProxyId,
      signedPaymentAuthorization: this.signedPaymentAuthorization,
      status: effectiveStatus,
      paymentAuthorizationLink: this.paymentAuthorizationLink,
      payees: this.payees,
      completed: isCompleteStatus(effectiveStatus),
    );
  }

  static bool isCompleteStatus(PaymentAuthorizationStatusEnum status) {
    return status == PaymentAuthorizationStatusEnum.Processed;
  }

  static String statusAsText(ProxyLocalizations localizations, PaymentAuthorizationStatusEnum status) {
    switch (status) {
      case PaymentAuthorizationStatusEnum.Registered:
        return localizations.registered;
      case PaymentAuthorizationStatusEnum.Rejected:
        return localizations.rejected;
      case PaymentAuthorizationStatusEnum.CancelledByPayer:
        return localizations.cancelledStatus;
      case PaymentAuthorizationStatusEnum.CancelledByPayee:
        return localizations.cancelledStatus;
      case PaymentAuthorizationStatusEnum.InProcess:
        return localizations.inProcess;
      case PaymentAuthorizationStatusEnum.Processed:
        return localizations.processedStatus;
      case PaymentAuthorizationStatusEnum.InsufficientFunds:
        return localizations.insufficientFundsStatus;
      case PaymentAuthorizationStatusEnum.Expired:
        return localizations.expiredStatus;
      case PaymentAuthorizationStatusEnum.Error:
        return localizations.errorStatus;
      default:
        print("Unhandled Event state: $status");
        return localizations.inTransit;
    }
  }

  Map<String, dynamic> toJson() => _$PaymentAuthorizationEntityToJson(this);

  static PaymentAuthorizationEntity fromJson(Map json) => _$PaymentAuthorizationEntityFromJson(json);

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return statusAsText(localizations, status);
  }

  IconData get icon {
    return Icons.file_upload;
  }

  bool get isCancelPossible {
    return cancelPossibleStatuses.contains(status);
  }
}
