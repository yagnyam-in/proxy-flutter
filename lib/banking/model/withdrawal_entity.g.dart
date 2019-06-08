// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEntity _$WithdrawalEntityFromJson(Map<String, dynamic> json) {
  return WithdrawalEntity(
      id: json['id'] as int,
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      withdrawalId: json['withdrawalId'] as String,
      completed: json['completed'] as bool,
      status: _$enumDecode(_$WithdrawalStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map<String, dynamic>),
      payerAccountId: ProxyAccountId.fromJson(
          json['payerAccountId'] as Map<String, dynamic>),
      payerProxyId:
          ProxyId.fromJson(json['payerProxyId'] as Map<String, dynamic>),
      signedWithdrawalRequestJson:
          json['signedWithdrawalRequestJson'] as String,
      receivingAccountId: json['receivingAccountId'] as int,
      destinationAccountNumber: json['destinationAccountNumber'] as String,
      destinationAccountBank: json['destinationAccountBank'] as String);
}

Map<String, dynamic> _$WithdrawalEntityToJson(WithdrawalEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'proxyUniverse': instance.proxyUniverse,
      'withdrawalId': instance.withdrawalId,
      'creationTime': instance.creationTime.toIso8601String(),
      'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'completed': instance.completed,
      'status': _$WithdrawalStatusEnumEnumMap[instance.status],
      'amount': instance.amount,
      'payerAccountId': instance.payerAccountId,
      'receivingAccountId': instance.receivingAccountId,
      'destinationAccountNumber': instance.destinationAccountNumber,
      'destinationAccountBank': instance.destinationAccountBank,
      'payerProxyId': instance.payerProxyId,
      'signedWithdrawalRequestJson': instance.signedWithdrawalRequestJson
    };

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

const _$WithdrawalStatusEnumEnumMap = <WithdrawalStatusEnum, dynamic>{
  WithdrawalStatusEnum.Registered: 'Registered',
  WithdrawalStatusEnum.Rejected: 'Rejected',
  WithdrawalStatusEnum.InTransit: 'InTransit',
  WithdrawalStatusEnum.Completed: 'Completed',
  WithdrawalStatusEnum.FailedInTransit: 'FailedInTransit',
  WithdrawalStatusEnum.FailedCompleted: 'FailedCompleted'
};
