// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepositEvent _$DepositEventFromJson(Map json) {
  return DepositEvent(
      eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
      id: json['id'] as int,
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      completed: json['completed'] as bool,
      depositId: json['depositId'] as String,
      status: _$enumDecode(_$DepositStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map),
      destinationProxyAccountId:
          ProxyAccountId.fromJson(json['destinationProxyAccountId'] as Map),
      depositLink: json['depositLink'] as String);
}

Map<String, dynamic> _$DepositEventToJson(DepositEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'proxyUniverse': instance.proxyUniverse,
      'eventType': _$EventTypeEnumMap[instance.eventType],
      'creationTime': instance.creationTime.toIso8601String(),
      'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'completed': instance.completed,
      'status': _$DepositStatusEnumEnumMap[instance.status],
      'amount': instance.amount.toJson(),
      'destinationProxyAccountId': instance.destinationProxyAccountId.toJson(),
      'depositLink': instance.depositLink,
      'depositId': instance.depositId
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

const _$EventTypeEnumMap = <EventType, dynamic>{
  EventType.Unknown: 'Unknown',
  EventType.Deposit: 'Deposit',
  EventType.Withdraw: 'Withdraw',
  EventType.Payment: 'Payment',
  EventType.Fx: 'Fx'
};

const _$DepositStatusEnumEnumMap = <DepositStatusEnum, dynamic>{
  DepositStatusEnum.Created: 'Created',
  DepositStatusEnum.Registered: 'Registered',
  DepositStatusEnum.Rejected: 'Rejected',
  DepositStatusEnum.InProcess: 'InProcess',
  DepositStatusEnum.Completed: 'Completed',
  DepositStatusEnum.Cancelled: 'Cancelled'
};
