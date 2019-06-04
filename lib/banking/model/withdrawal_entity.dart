import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class WithdrawalEntity {
  static final Set<WithdrawalStatusEnum> cancellableStatuses = Set.of([
    WithdrawalStatusEnum.Registered,
    WithdrawalStatusEnum.FailedInTransit,
  ]);

  final int id;
  final String proxyUniverse;
  final String withdrawalId;
  final DateTime creationTime;
  final DateTime lastUpdatedTime;
  final bool completed;
  final WithdrawalStatusEnum status;
  final Amount amount;
  final ProxyAccountId payerAccountId;
  final int receivingAccountId;
  final String destinationAccountNumber;
  final String destinationAccountBank;
  final ProxyId payerProxyId;
  final String signedWithdrawalRequestJson;
  SignedMessage<Withdrawal> _signedWithdrawal;

  WithdrawalEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.withdrawalId,
    @required this.completed,
    @required this.status,
    @required this.amount,
    @required this.payerAccountId,
    @required this.payerProxyId,
    @required this.signedWithdrawalRequestJson,
    @required this.receivingAccountId,
    @required this.destinationAccountNumber,
    @required this.destinationAccountBank,
  });

  SignedMessage<Withdrawal> get signedWithdrawal {
    if (_signedWithdrawal == null) {
      print("Constructing from $signedWithdrawalRequestJson");
      _signedWithdrawal = MessageBuilder.instance()
          .buildSignedMessage(signedWithdrawalRequestJson, Withdrawal.fromJson);
    }
    return _signedWithdrawal;
  }

  WithdrawalEntity copy(
      {int id, WithdrawalStatusEnum status, DateTime lastUpdatedTime}) {
    WithdrawalStatusEnum effectiveStatus = status ?? this.status;
    return WithdrawalEntity(
      id: id ?? this.id,
      proxyUniverse: this.proxyUniverse,
      withdrawalId: this.withdrawalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      payerAccountId: this.payerAccountId,
      payerProxyId: this.payerProxyId,
      signedWithdrawalRequestJson: this.signedWithdrawalRequestJson,
      status: effectiveStatus,
      receivingAccountId: this.receivingAccountId,
      destinationAccountNumber: this.destinationAccountNumber,
      destinationAccountBank: this.destinationAccountBank,
    );
  }


  static WithdrawalStatusEnum stringToWithdrawalStatus(
      String value, {
        WithdrawalStatusEnum orElse = WithdrawalStatusEnum.Registered,
      }) {
    return ConversionUtils.stringToEnum(
      value,
      orElse: orElse,
      values: WithdrawalStatusEnum.values,
      enumName: "WithdrawalStatusEnum",
    );
  }

  static String withdrawalStatusToString(
      WithdrawalStatusEnum value,
      ) {
    return ConversionUtils.enumToString(
      value,
      enumName: "WithdrawalStatusEnum",
    );
  }


  static bool isCompleteStatus(WithdrawalStatusEnum status) {
    return status == WithdrawalStatusEnum.Completed ||
        status == WithdrawalStatusEnum.FailedCompleted;
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
      case WithdrawalStatusEnum.Registered:
        return localizations.registered;
      case WithdrawalStatusEnum.Rejected:
        return localizations.rejected;
      case WithdrawalStatusEnum.InTransit:
        return localizations.inTransit;
      case WithdrawalStatusEnum.Completed:
        return localizations.completed;
      case WithdrawalStatusEnum.FailedInTransit:
        return localizations.failedInTransit;
      case WithdrawalStatusEnum.FailedCompleted:
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
    return cancellableStatuses.contains(status);
  }
}
