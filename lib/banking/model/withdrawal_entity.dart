import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/localizations.dart';
import 'package:promo/utils/conversion_utils.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';

import 'abstract_entity.dart';

part 'withdrawal_entity.g.dart';

@JsonSerializable()
class WithdrawalEntity extends AbstractEntity<WithdrawalEntity> {
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const WITHDRAWAL_ID = "withdrawalId";
  static const BANK_ID = "bankId";

  static final Set<WithdrawalStatusEnum> cancellableStatuses = Set.of([
    WithdrawalStatusEnum.Registered,
    WithdrawalStatusEnum.FailedInTransit,
  ]);

  @JsonKey(nullable: false)
  String internalId;

  @JsonKey(nullable: false)
  String eventInternalId;

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(name: WITHDRAWAL_ID, nullable: false)
  final String withdrawalId;

  @JsonKey(name: BANK_ID, nullable: false)
  final String bankId;

  @JsonKey(nullable: false)
  final DateTime creationTime;

  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;

  @JsonKey(nullable: false)
  final bool completed;

  @JsonKey(nullable: false)
  final WithdrawalStatusEnum status;

  @JsonKey(nullable: false)
  final Amount amount;

  @JsonKey(nullable: false)
  final ProxyAccountId payerProxyAccountId;

  @JsonKey(nullable: false)
  final String receivingAccountId;

  @JsonKey(nullable: false)
  final String destinationAccountNumber;

  @JsonKey(nullable: false)
  final String destinationAccountBank;

  @JsonKey(nullable: false)
  final ProxyId payerProxyId;

  @JsonKey(nullable: false, fromJson: Withdrawal.signedMessageFromJson)
  SignedMessage<Withdrawal> signedWithdrawal;

  WithdrawalEntity({
    this.internalId,
    this.eventInternalId,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.withdrawalId,
    @required this.completed,
    @required this.status,
    @required this.amount,
    @required this.payerProxyAccountId,
    @required this.payerProxyId,
    @required this.signedWithdrawal,
    @required this.receivingAccountId,
    @required this.destinationAccountNumber,
    @required this.destinationAccountBank,
    String bankId,
  }) : this.bankId = payerProxyAccountId.bankId {
    assert(bankId == null || this.bankId == bankId);
  }

  WithdrawalEntity copy({
    WithdrawalStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    WithdrawalStatusEnum effectiveStatus = status ?? this.status;
    return WithdrawalEntity(
      internalId: this.internalId,
      eventInternalId: this.eventInternalId,
      proxyUniverse: this.proxyUniverse,
      withdrawalId: this.withdrawalId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      payerProxyAccountId: this.payerProxyAccountId,
      payerProxyId: this.payerProxyId,
      signedWithdrawal: this.signedWithdrawal,
      status: effectiveStatus,
      receivingAccountId: this.receivingAccountId,
      destinationAccountNumber: this.destinationAccountNumber,
      destinationAccountBank: this.destinationAccountBank,
    );
  }

  @override
  WithdrawalEntity copyWithInternalId(String id) {
    this.internalId = id;
    return this;
  }

  WithdrawalEntity copyWithEventInternalId(String eventId) {
    this.eventInternalId = eventId;
    return this;
  }

  @override
  Map<String, dynamic> toJson() => _$WithdrawalEntityToJson(this);

  static WithdrawalEntity fromJson(Map json) => _$WithdrawalEntityFromJson(json);

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
    return status == WithdrawalStatusEnum.Completed || status == WithdrawalStatusEnum.FailedCompleted;
  }

  String getTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.withdrawalEventSubTitle(destinationAccountNumber);
  }

  static String statusAsText(ProxyLocalizations localizations, WithdrawalStatusEnum status) {
    switch (status) {
      case WithdrawalStatusEnum.Created:
        return localizations.created;
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

  IconData get icon {
    return Icons.file_upload;
  }

  bool get isCancelPossible {
    return cancellableStatuses.contains(status);
  }

  String getAmountAsText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatusAsText(ProxyLocalizations localizations) {
    return statusAsText(localizations, status);
  }
}
