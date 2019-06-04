import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_messages/banking.dart';

class PaymentAuthorizationEntity {
  static final Set<PaymentAuthorizationStatusEnum> cancellableStatuses = {
    PaymentAuthorizationStatusEnum.Registered,
  };

  final int id;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final DateTime creationTime;
  final DateTime lastUpdatedTime;

  final PaymentAuthorizationStatusEnum status;
  final Amount amount;
  final ProxyAccountId payerAccountId;
  final ProxyId payerProxyId;

  final String signedPaymentAuthorizationRequestJson;
  final List<PaymentAuthorizationPayeeEntity> payees;

  final String paymentLink;
  SignedMessage<PaymentAuthorization> _signedPaymentAuthorizationRequest;

  PaymentAuthorizationEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.payerProxyId,
    @required this.signedPaymentAuthorizationRequestJson,
    @required this.paymentLink,
    @required this.payees,
  });

  SignedMessage<PaymentAuthorization> get signedPaymentAuthorization {
    if (_signedPaymentAuthorizationRequest == null) {
      print("Constructing from $signedPaymentAuthorizationRequestJson");
      _signedPaymentAuthorizationRequest = MessageBuilder.instance()
          .buildSignedMessage(signedPaymentAuthorizationRequestJson,
              PaymentAuthorization.fromJson);
    }
    return _signedPaymentAuthorizationRequest;
  }

  PaymentAuthorizationEntity copy({
    int id,
    PaymentAuthorizationStatusEnum status,
    DateTime lastUpdatedTime,
    List<PaymentAuthorizationPayeeEntity> payees,
  }) {
    PaymentAuthorizationStatusEnum effectiveStatus = status ?? this.status;
    return PaymentAuthorizationEntity(
      id: id ?? this.id,
      proxyUniverse: this.proxyUniverse,
      paymentAuthorizationId: this.paymentAuthorizationId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      amount: this.amount,
      payerAccountId: this.payerAccountId,
      payerProxyId: this.payerProxyId,
      signedPaymentAuthorizationRequestJson:
          this.signedPaymentAuthorizationRequestJson,
      status: effectiveStatus,
      paymentLink: this.paymentLink,
      payees: payees ?? this.payees,
    );
  }

  static bool isCompleteStatus(PaymentAuthorizationStatusEnum status) {
    return status == PaymentAuthorizationStatusEnum.Processed;
  }

  String getStatus(ProxyLocalizations localizations) {
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

  bool isCancellable() {
    return cancellableStatuses.contains(status);
  }
}
