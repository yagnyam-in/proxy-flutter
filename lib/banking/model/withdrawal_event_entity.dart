import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

enum WithdrawalEventStatus {
  InProcess,
  Created,
  Registered,
  Rejected,
  InTransit,
  Completed,
  FailedInTransit,
  FailedCompleted,
}

class WithdrawalEventEntity extends EventEntity {
  final WithdrawalEventStatus status;
  final Amount amount;
  final ProxyAccountId accountId;
  final String destinationAccountNumber;
  final String destinationAccountBank;
  final ProxyId ownerId;
  final String signedWithdrawalRequestJson;
  SignedMessage<Withdrawal> _signedWithdrawal;

  WithdrawalEventEntity({
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required String eventId,
    bool completed,
    @required this.status,
    @required this.amount,
    @required this.accountId,
    @required this.ownerId,
    @required this.signedWithdrawalRequestJson,
    @required this.destinationAccountNumber,
    @required this.destinationAccountBank,
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
    row[EventEntity.PAYER_PROXY_ACCOUNT_ID] = accountId.accountId;
    row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID] = accountId.bankId;
    row[EventEntity.PAYER_PROXY_ID] = ownerId.id;
    row[EventEntity.PAYER_PROXY_SHA] = ownerId.sha256Thumbprint;
    row[EventEntity.SIGNED_REQUEST] = signedWithdrawalRequestJson;
    row[EventEntity.PAYEE_ACCOUNT_NUMBER] = destinationAccountNumber;
    row[EventEntity.PAYEE_ACCOUNT_BANK] = destinationAccountBank;
    return row;
  }

  SignedMessage<Withdrawal> get signedWithdrawal {
    if (_signedWithdrawal == null) {
      print("Constructing from $signedWithdrawalRequestJson");
      _signedWithdrawal = MessageBuilder.instance()
          .buildSignedMessage(signedWithdrawalRequestJson, Withdrawal.fromJson);
    }
    return _signedWithdrawal;
  }

  WithdrawalEventEntity.fromRow(Map<dynamic, dynamic> row)
      : status = _stringToEventStatus(row[EventEntity.STATUS]),
        amount = Amount(row[EventEntity.PRIMARY_AMOUNT_CURRENCY],
            row[EventEntity.PRIMARY_AMOUNT]),
        accountId = ProxyAccountId(
            accountId: row[EventEntity.PAYER_PROXY_ACCOUNT_ID],
            bankId: row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID],
            proxyUniverse: row[EventEntity.PROXY_UNIVERSE]),
        ownerId = ProxyId(
            row[EventEntity.PAYER_PROXY_ID], row[EventEntity.PAYER_PROXY_SHA]),
        signedWithdrawalRequestJson = row[EventEntity.SIGNED_REQUEST],
        destinationAccountNumber = row[EventEntity.PAYEE_ACCOUNT_NUMBER],
        destinationAccountBank = row[EventEntity.PAYEE_ACCOUNT_BANK],
        super.fromRow(row);

  WithdrawalEventEntity copy(
      {WithdrawalEventStatus status, DateTime lastUpdatedTime}) {
    WithdrawalEventStatus effectiveStatus = status ?? this.status;
    return WithdrawalEventEntity(
      id: this.id,
      proxyUniverse: this.proxyUniverse,
      eventId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      accountId: this.accountId,
      ownerId: this.ownerId,
      signedWithdrawalRequestJson: this.signedWithdrawalRequestJson,
      status: effectiveStatus,
      destinationAccountNumber: this.destinationAccountNumber,
      destinationAccountBank: this.destinationAccountBank,
    );
  }

  static bool isCompleteStatus(WithdrawalEventStatus status) {
    return status == WithdrawalEventStatus.Completed ||
        status == WithdrawalEventStatus.FailedCompleted;
  }

  static WithdrawalEventStatus _stringToEventStatus(String value,
      {WithdrawalEventStatus orElse = WithdrawalEventStatus.InProcess}) {
    return WithdrawalEventStatus.values.firstWhere(
        (e) => ConversionUtils.isEnumEqual(e, value,
            enumName: "WithdrawalEventStatus"),
        orElse: () => orElse);
  }

  static String _eventStatusToString(WithdrawalEventStatus eventType) {
    return eventType
        ?.toString()
        ?.replaceFirst("WithdrawalEventStatus.", "")
        ?.toLowerCase();
  }

  static WithdrawalEventStatus toLocalStatus(
      WithdrawalStatusEnum backendStatus) {
    switch (backendStatus) {
      case WithdrawalStatusEnum.Registered:
        return WithdrawalEventStatus.Registered;
      case WithdrawalStatusEnum.Rejected:
        return WithdrawalEventStatus.Rejected;
      case WithdrawalStatusEnum.InTransit:
        return WithdrawalEventStatus.InTransit;
      case WithdrawalStatusEnum.Completed:
        return WithdrawalEventStatus.Completed;
      case WithdrawalStatusEnum.FailedInTransit:
        return WithdrawalEventStatus.FailedInTransit;
      case WithdrawalStatusEnum.FailedCompleted:
        return WithdrawalEventStatus.FailedCompleted;
      default:
        print("Unhandled Event state: $backendStatus");
        return WithdrawalEventStatus.InProcess;
    }
  }

  String getTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventSubTitle(destinationAccountNumber);
  }

  String getAmountText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatus(ProxyLocalizations localizations) {
    switch (status) {
      case WithdrawalEventStatus.Registered:
        return localizations.registered;
      case WithdrawalEventStatus.Rejected:
        return localizations.rejected;
      case WithdrawalEventStatus.InTransit:
        return localizations.inTransit;
      case WithdrawalEventStatus.Completed:
        return localizations.completed;
      case WithdrawalEventStatus.FailedInTransit:
        return localizations.failedInTransit;
      case WithdrawalEventStatus.FailedCompleted:
        return localizations.failedCompleted;
      default:
        print("Unhandled Event state: $status");
        return localizations.inTransit;
    }
  }

  IconData icon() {
    return Icons.file_upload;
  }

  bool isCancellable() {
    if (status == WithdrawalEventStatus.Registered) {
      return true;
    } else {
      return false;
    }
  }
}
