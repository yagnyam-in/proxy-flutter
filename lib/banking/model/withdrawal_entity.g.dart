// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEntity _$WithdrawalEntityFromJson(Map json) {
  return WithdrawalEntity(
    internalId: json['internalId'] as String,
    eventInternalId: json['eventInternalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    withdrawalId: json['withdrawalId'] as String,
    completed: json['completed'] as bool,
    status: _$enumDecode(_$WithdrawalStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    payerProxyAccountId:
        ProxyAccountId.fromJson(json['payerProxyAccountId'] as Map),
    payerProxyId: ProxyId.fromJson(json['payerProxyId'] as Map),
    signedWithdrawal:
        Withdrawal.signedMessageFromJson(json['signedWithdrawal'] as Map),
    receivingAccountId: json['receivingAccountId'] as String,
    destinationAccountNumber: json['destinationAccountNumber'] as String,
    destinationAccountBank: json['destinationAccountBank'] as String,
    bankId: json['bankId'] as String,
  );
}

Map<String, dynamic> _$WithdrawalEntityToJson(WithdrawalEntity instance) =>
    <String, dynamic>{
      'internalId': instance.internalId,
      'eventInternalId': instance.eventInternalId,
      'proxyUniverse': instance.proxyUniverse,
      'withdrawalId': instance.withdrawalId,
      'bankId': instance.bankId,
      'creationTime': instance.creationTime.toIso8601String(),
      'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'completed': instance.completed,
      'status': _$WithdrawalStatusEnumEnumMap[instance.status],
      'amount': instance.amount.toJson(),
      'payerProxyAccountId': instance.payerProxyAccountId.toJson(),
      'receivingAccountId': instance.receivingAccountId,
      'destinationAccountNumber': instance.destinationAccountNumber,
      'destinationAccountBank': instance.destinationAccountBank,
      'payerProxyId': instance.payerProxyId.toJson(),
      'signedWithdrawal': instance.signedWithdrawal.toJson(),
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

const _$WithdrawalStatusEnumEnumMap = {
  WithdrawalStatusEnum.Created: 'Created',
  WithdrawalStatusEnum.Registered: 'Registered',
  WithdrawalStatusEnum.Rejected: 'Rejected',
  WithdrawalStatusEnum.InTransit: 'InTransit',
  WithdrawalStatusEnum.Completed: 'Completed',
  WithdrawalStatusEnum.FailedInTransit: 'FailedInTransit',
  WithdrawalStatusEnum.FailedCompleted: 'FailedCompleted',
};
