import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class DepositEntity with ProxyUtils {
  static final Set<DepositStatusEnum> cancellableStatuses = {
    DepositStatusEnum.Registered,
  };
  static final Set<DepositStatusEnum> depositPossibleStatuses = {
    DepositStatusEnum.Registered,
  };

  final int id;
  final String proxyUniverse;
  final String depositId;
  final DateTime creationTime;
  final DateTime lastUpdatedTime;
  final bool completed;
  final DepositStatusEnum status;
  final Amount amount;
  final ProxyAccountId destinationProxyAccountId;
  final ProxyId destinationProxyAccountOwnerProxyId;
  final String signedDepositRequestJson;
  final String depositLink;
  SignedMessage<DepositRequest> _signedDepositRequest;

  DepositEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.depositId,
    @required this.completed,
    @required this.status,
    @required this.amount,
    @required this.destinationProxyAccountId,
    @required this.destinationProxyAccountOwnerProxyId,
    this.depositLink,
    this.signedDepositRequestJson,
  });

  SignedMessage<DepositRequest> get signedDepositRequest {
    if (_signedDepositRequest == null) {
      print("Constructing from $signedDepositRequestJson");
      _signedDepositRequest = MessageBuilder.instance().buildSignedMessage(
          signedDepositRequestJson, DepositRequest.fromJson);
    }
    return _signedDepositRequest;
  }

  DepositEntity copy({
    int id,
    String depositLink,
    String signedDepositRequestJson,
    DepositStatusEnum status,
    DateTime lastUpdatedTime,
  }) {
    DepositStatusEnum effectiveStatus = status ?? this.status;
    return DepositEntity(
      id: id ?? this.id,
      proxyUniverse: this.proxyUniverse,
      depositId: this.depositId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      destinationProxyAccountId: this.destinationProxyAccountId,
      destinationProxyAccountOwnerProxyId:
          this.destinationProxyAccountOwnerProxyId,
      signedDepositRequestJson:
          signedDepositRequestJson ?? this.signedDepositRequestJson,
      depositLink: depositLink ?? this.depositLink,
      status: effectiveStatus,
    );
  }

  static bool isCompleteStatus(DepositStatusEnum status) {
    return status == DepositStatusEnum.Completed ||
        status == DepositStatusEnum.Cancelled;
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

  static String statusDisplayMessage(ProxyLocalizations localizations, DepositStatusEnum status) {
    switch (status) {
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


}
