// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepositEntity _$DepositEntityFromJson(Map<String, dynamic> json) {
  return DepositEntity(
      id: json['id'] as int,
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      depositId: json['depositId'] as String,
      completed: json['completed'] as bool,
      status: _$enumDecode(_$DepositStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map<String, dynamic>),
      destinationProxyAccountId: ProxyAccountId.fromJson(
          json['destinationProxyAccountId'] as Map<String, dynamic>),
      destinationProxyAccountOwnerProxyId: ProxyId.fromJson(
          json['destinationProxyAccountOwnerProxyId'] as Map<String, dynamic>),
      depositLink: json['depositLink'] as String,
      signedDepositRequestJson: json['signedDepositRequestJson'] as String);
}

Map<String, dynamic> _$DepositEntityToJson(DepositEntity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'proxyUniverse': instance.proxyUniverse,
      'depositId': instance.depositId,
      'creationTime': instance.creationTime.toIso8601String(),
      'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'completed': instance.completed,
      'status': _$DepositStatusEnumEnumMap[instance.status],
      'amount': instance.amount,
      'destinationProxyAccountId': instance.destinationProxyAccountId,
      'destinationProxyAccountOwnerProxyId':
          instance.destinationProxyAccountOwnerProxyId,
      'signedDepositRequestJson': instance.signedDepositRequestJson,
      'depositLink': instance.depositLink
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

const _$DepositStatusEnumEnumMap = <DepositStatusEnum, dynamic>{
  DepositStatusEnum.Registered: 'Registered',
  DepositStatusEnum.Rejected: 'Rejected',
  DepositStatusEnum.InProcess: 'InProcess',
  DepositStatusEnum.Completed: 'Completed',
  DepositStatusEnum.Cancelled: 'Cancelled'
};
