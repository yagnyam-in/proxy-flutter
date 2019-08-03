// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepositEntity _$DepositEntityFromJson(Map json) {
  return DepositEntity(
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      depositId: json['depositId'] as String,
      completed: json['completed'] as bool,
      status: _$enumDecode(_$DepositStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map),
      destinationProxyAccountId:
          ProxyAccountId.fromJson(json['destinationProxyAccountId'] as Map),
      destinationProxyAccountOwnerProxyId:
          ProxyId.fromJson(json['destinationProxyAccountOwnerProxyId'] as Map),
      depositLink: json['depositLink'] as String,
      signedDepositRequest: DepositRequest.signedMessageFromJson(
          json['signedDepositRequest'] as Map));
}

Map<String, dynamic> _$DepositEntityToJson(DepositEntity instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'depositId': instance.depositId,
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'completed': instance.completed,
    'status': _$DepositStatusEnumEnumMap[instance.status],
    'amount': instance.amount.toJson(),
    'destinationProxyAccountId': instance.destinationProxyAccountId.toJson(),
    'destinationProxyAccountOwnerProxyId':
        instance.destinationProxyAccountOwnerProxyId.toJson(),
    'signedDepositRequest': instance.signedDepositRequest.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('depositLink', instance.depositLink);
  return val;
}

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
  DepositStatusEnum.Created: 'Created',
  DepositStatusEnum.Registered: 'Registered',
  DepositStatusEnum.Rejected: 'Rejected',
  DepositStatusEnum.InProcess: 'InProcess',
  DepositStatusEnum.Completed: 'Completed',
  DepositStatusEnum.Cancelled: 'Cancelled'
};
