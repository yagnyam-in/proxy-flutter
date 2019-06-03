import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class PaymentEventEntity extends EventEntity {
  static final Set<PaymentStatusEnum> cancellableStatuses = Set.of([
    PaymentStatusEnum.Registered,
  ]);

  final PaymentStatusEnum status;
  final Amount amount;
  final bool inward;
  final ProxyAccountId payerAccountId;
  final ProxyAccountId payeeAccountId;
  final ProxyId payerProxyId;
  final ProxyId payeeProxyId;
  final String signedPaymentAuthorizationRequestJson;
  final String paymentLink;
  SignedMessage<PaymentAuthorization> _signedPaymentAuthorizationRequest;

  PaymentEventEntity({
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required String eventId,
    bool completed,
    @required this.status,
    @required this.amount,
    @required this.inward,
    @required this.payerAccountId,
    this.payeeAccountId,
    @required this.payerProxyId,
    this.payeeProxyId,
    @required this.signedPaymentAuthorizationRequestJson,
    @required this.paymentLink,
  }) : super(
          id: id,
          proxyUniverse: proxyUniverse,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          eventType: EventType.Withdraw,
          eventId: eventId,
          completed: isCompleteStatus(status),
        );

  @override
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = super.toRow();
    row[EventEntity.STATUS] = _eventStatusToString(status);
    row[EventEntity.PRIMARY_AMOUNT_CURRENCY] = amount.currency;
    row[EventEntity.PRIMARY_AMOUNT] = amount.value;
    row[EventEntity.INWARD] = inward;

    row[EventEntity.PAYER_PROXY_ACCOUNT_ID] = payerAccountId.accountId;
    row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID] = payerAccountId.bankId;
    row[EventEntity.PAYER_PROXY_ID] = payerProxyId.id;
    row[EventEntity.PAYER_PROXY_SHA] = payerProxyId.sha256Thumbprint;

    row[EventEntity.PAYEE_PROXY_ACCOUNT_ID] = payeeAccountId.accountId;
    row[EventEntity.PAYEE_PROXY_ACCOUNT_BANK_ID] = payeeAccountId.bankId;
    row[EventEntity.PAYEE_PROXY_ID] = payeeProxyId.id;
    row[EventEntity.PAYEE_PROXY_SHA] = payeeProxyId.sha256Thumbprint;

    row[EventEntity.SIGNED_PAYMENT_AUTHORIZATION_REQUEST] = signedPaymentAuthorizationRequestJson;
    row[EventEntity.PAYMENT_LINK] = paymentLink;
    return row;
  }

  SignedMessage<PaymentAuthorization> get signedPaymentAuthorization {
    if (_signedPaymentAuthorizationRequest == null) {
      print("Constructing from $signedPaymentAuthorizationRequestJson");
      _signedPaymentAuthorizationRequest = MessageBuilder.instance()
          .buildSignedMessage(signedPaymentAuthorizationRequestJson, PaymentAuthorization.fromJson);
    }
    return _signedPaymentAuthorizationRequest;
  }

  PaymentEventEntity.fromRow(Map<dynamic, dynamic> row)
      : status = _stringToEventStatus(row[EventEntity.STATUS]),
        inward = (row[EventEntity.INWARD] as int) != 0,
        amount = Amount(
          row[EventEntity.PRIMARY_AMOUNT_CURRENCY],
          row[EventEntity.PRIMARY_AMOUNT],
        ),
        payerAccountId = ProxyAccountId(
          accountId: row[EventEntity.PAYER_PROXY_ACCOUNT_ID],
          bankId: row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID],
          proxyUniverse: row[EventEntity.PROXY_UNIVERSE],
        ),
        payeeAccountId = ProxyAccountId(
          accountId: row[EventEntity.PAYEE_PROXY_ACCOUNT_ID],
          bankId: row[EventEntity.PAYEE_PROXY_ACCOUNT_BANK_ID],
          proxyUniverse: row[EventEntity.PROXY_UNIVERSE],
        ),
        payerProxyId = ProxyId(
          row[EventEntity.PAYER_PROXY_ID],
          row[EventEntity.PAYER_PROXY_SHA],
        ),
        payeeProxyId = ProxyId(
          row[EventEntity.PAYEE_PROXY_ID],
          row[EventEntity.PAYEE_PROXY_SHA],
        ),
        signedPaymentAuthorizationRequestJson = row[EventEntity.SIGNED_PAYMENT_AUTHORIZATION_REQUEST],
        paymentLink = row[EventEntity.PAYMENT_LINK],
        super.fromRow(row);

  PaymentEventEntity copy({
    PaymentStatusEnum status,
    DateTime lastUpdatedTime,
    ProxyId payeeProxyId,
    ProxyAccountId payeeAccountId,
  }) {
    PaymentStatusEnum effectiveStatus = status ?? this.status;
    return PaymentEventEntity(
      id: this.id,
      proxyUniverse: this.proxyUniverse,
      eventId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      inward: this.inward,
      payerAccountId: this.payerAccountId,
      payerProxyId: this.payerProxyId,
      signedPaymentAuthorizationRequestJson: this.signedPaymentAuthorizationRequestJson,
      status: effectiveStatus,
      payeeAccountId: payeeAccountId ?? this.payeeAccountId,
      payeeProxyId: payeeProxyId ?? this.payeeProxyId,
      paymentLink: this.paymentLink,
    );
  }

  static bool isCompleteStatus(PaymentStatusEnum status) {
    return status == PaymentStatusEnum.Processed;
  }

  static PaymentStatusEnum _stringToEventStatus(String value,
      {PaymentStatusEnum orElse = PaymentStatusEnum.InProcess}) {
    return PaymentStatusEnum.values
        .firstWhere((e) => ConversionUtils.isEnumEqual(e, value, enumName: "PaymentStatusEnum"), orElse: () => orElse);
  }

  static String _eventStatusToString(PaymentStatusEnum eventType) {
    return eventType?.toString()?.replaceFirst("PaymentStatusEnum.", "")?.toLowerCase();
  }

  String getTitle(ProxyLocalizations localizations) {
    return localizations.paymentEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    if (inward) {
      return localizations.inwardPaymentEventSubTitle(payeeProxyId.id);
    }
    if (payeeProxyId == null) {
      return  localizations.outwardPaymentToUnknownEventSubTitle;
    }
    return  localizations.outwardPaymentEventSubTitle(payeeProxyId.id);
  }

  String getAmountText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatus(ProxyLocalizations localizations) {
    switch (status) {
      case PaymentStatusEnum.Registered:
        return localizations.registered;
      case PaymentStatusEnum.Rejected:
        return localizations.rejected;
      case PaymentStatusEnum.CancelledByPayer:
        return inward ? localizations.cancelledByPayerStatus : localizations.cancelledStatus;
      case PaymentStatusEnum.CancelledByPayee:
        return inward ? localizations.cancelledByPayeeStatus : localizations.cancelledStatus;
      case PaymentStatusEnum.InProcess:
        return localizations.inProcess;
      case PaymentStatusEnum.Processed:
        return localizations.processedStatus;
      case PaymentStatusEnum.InsufficientFunds:
        return localizations.insufficientFundsStatus;
      case PaymentStatusEnum.Expired:
        return localizations.expiredStatus;
      case PaymentStatusEnum.Error:
        return localizations.errorStatus;
      default:
        print("Unhandled Event state: $status");
        return localizations.inTransit;
    }
  }

  IconData icon() {
    return Icons.file_upload;
  }

  bool isCancellable() {
    return cancellableStatuses.contains(status);
  }
}
