import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

part 'deposit_entity.g.dart';

@JsonSerializable()
class DepositEntity with ProxyUtils {

  @JsonKey(nullable: false)
  final String proxyUniverse;
  @JsonKey(nullable: false)
  final String depositId;
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
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.depositId,
    @required this.completed,
    @required this.status,
    @required this.amount,
    @required this.destinationProxyAccountId,
    @required this.destinationProxyAccountOwnerProxyId,
    @required this.depositLink,
    @required this.signedDepositRequest,
  });

  DepositEntity copy({
    DepositStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    DepositStatusEnum effectiveStatus = status ?? this.status;
    return DepositEntity(
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
        return localizations.completed;
      case DepositStatusEnum.Cancelled:
        return localizations.cancelled;
      default:
        print("Unhandled Event state: $status");
        return localizations.inProcess;
    }
  }

  Map<String, dynamic> toJson() => _$DepositEntityToJson(this);

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
    return depositPossibleStatuses.contains(status) && isNotEmpty(depositLink);
  }
}
