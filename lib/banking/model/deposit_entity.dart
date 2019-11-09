import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/abstract_entity.dart';
import 'package:promo/localizations.dart';
import 'package:promo/utils/conversion_utils.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:quiver/strings.dart';

part 'deposit_entity.g.dart';

@JsonSerializable()
class DepositEntity extends AbstractEntity<DepositEntity> {
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const DEPOSIT_ID = "depositId";
  static const BANK_ID = "bankId";

  @JsonKey(nullable: false)
  String internalId;
  @JsonKey(nullable: false)
  String eventInternalId;
  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;
  @JsonKey(name: DEPOSIT_ID, nullable: false)
  final String depositId;
  @JsonKey(name: BANK_ID, nullable: false)
  final String bankId;
  @JsonKey(nullable: false)
  final DateTime creationTime;
  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;
  @JsonKey(nullable: false)
  final bool completed;
  @JsonKey(nullable: false)
  final DepositStatusEnum status;
  @JsonKey(nullable: false)
  final Amount amount;
  @JsonKey(nullable: false)
  final ProxyAccountId destinationProxyAccountId;
  @JsonKey(nullable: false)
  final ProxyId destinationProxyAccountOwnerProxyId;
  @JsonKey(nullable: false, fromJson: DepositRequest.signedMessageFromJson)
  SignedMessage<DepositRequest> signedDepositRequest;
  @JsonKey(nullable: true)
  final String depositLink;

  DepositEntity({
    this.internalId,
    this.eventInternalId,
    @required this.proxyUniverse,
    @required this.depositId,
    @required this.completed,
    @required this.status,
    @required this.amount,
    @required this.destinationProxyAccountId,
    @required this.destinationProxyAccountOwnerProxyId,
    @required this.depositLink,
    @required this.signedDepositRequest,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    String bankId,
  }) : bankId = destinationProxyAccountId.bankId {
    assert(bankId == null || this.bankId == bankId);
  }

  DepositEntity copy({
    DepositStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    DepositStatusEnum effectiveStatus = status ?? this.status;
    return DepositEntity(
      internalId: this.internalId,
      eventInternalId: this.eventInternalId,
      proxyUniverse: this.proxyUniverse,
      depositId: this.depositId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      destinationProxyAccountId: this.destinationProxyAccountId,
      destinationProxyAccountOwnerProxyId: this.destinationProxyAccountOwnerProxyId,
      depositLink: this.depositLink,
      signedDepositRequest: this.signedDepositRequest,
      status: effectiveStatus,
    );
  }

  @override
  DepositEntity copyWithInternalId(String id) {
    internalId = id;
    return this;
  }

  DepositEntity copyWithEventInternalId(String eventId) {
    eventInternalId = eventId;
    return this;
  }

  static final Set<DepositStatusEnum> cancelPossibleStatuses = {
    DepositStatusEnum.Registered,
  };
  static final Set<DepositStatusEnum> depositPossibleStatuses = {
    DepositStatusEnum.Registered,
  };

  static bool isCompleteStatus(DepositStatusEnum status) {
    return status == DepositStatusEnum.Completed || status == DepositStatusEnum.Cancelled;
  }

  static DepositStatusEnum stringToDepositStatus(
    String value, {
    DepositStatusEnum orElse = DepositStatusEnum.InProcess,
  }) {
    return ConversionUtils.stringToEnum(
      value,
      orElse: orElse,
      values: DepositStatusEnum.values,
      enumName: "DepositStatusEnum",
    );
  }

  static String depositStatusToString(
    DepositStatusEnum value,
  ) {
    return ConversionUtils.enumToString(
      value,
      enumName: "DepositStatusEnum",
    );
  }

  static String statusAsText(ProxyLocalizations localizations, DepositStatusEnum status) {
    switch (status) {
      case DepositStatusEnum.Created:
        return localizations.created;
      case DepositStatusEnum.Registered:
        return localizations.waitingForFunds;
      case DepositStatusEnum.Rejected:
        return localizations.rejected;
      case DepositStatusEnum.InProcess:
        return localizations.inProcess;
      case DepositStatusEnum.Completed:
        return localizations.deposited;
      case DepositStatusEnum.Cancelled:
        return localizations.cancelled;
      default:
        print("Unhandled Event state: $status");
        return localizations.inProcess;
    }
  }

  @override
  Map<String, dynamic> toJson() => _$DepositEntityToJson(this);

  @override
  String toString() {
    return "$runtimeType(internalId: $internalId)";
  }

  static DepositEntity fromJson(Map json) => _$DepositEntityFromJson(json);

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

  bool get isDepositPossible {
    return depositPossibleStatuses.contains(status) && isNotBlank(depositLink);
  }
}
