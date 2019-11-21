// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DepositEvent _$DepositEventFromJson(Map json) {
  return DepositEvent(
    eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
    internalId: json['internalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    completed: json['completed'] as bool,
    active: json['active'] as bool,
    depositInternalId: json['depositInternalId'] as String,
    status: _$enumDecode(_$DepositStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    destinationProxyAccountId:
        ProxyAccountId.fromJson(json['destinationProxyAccountId'] as Map),
    depositLink: json['depositLink'] as String,
  );
}

Map<String, dynamic> _$DepositEventToJson(DepositEvent instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'eventType': _$EventTypeEnumMap[instance.eventType],
    'internalId': instance.internalId,
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'completed': instance.completed,
    'active': instance.active,
    'status': _$DepositStatusEnumEnumMap[instance.status],
    'amount': instance.amount.toJson(),
    'destinationProxyAccountId': instance.destinationProxyAccountId.toJson(),
    'depositLink': instance.depositLink,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('depositInternalId', instance.depositInternalId);
  return val;
}

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

const _$EventTypeEnumMap = {
  EventType.Unknown: 'Unknown',
  EventType.Deposit: 'Deposit',
  EventType.Withdrawal: 'Withdrawal',
  EventType.PaymentAuthorization: 'PaymentAuthorization',
  EventType.PaymentEncashment: 'PaymentEncashment',
  EventType.Fx: 'Fx',
};

const _$DepositStatusEnumEnumMap = {
  DepositStatusEnum.Created: 'Created',
  DepositStatusEnum.Registered: 'Registered',
  DepositStatusEnum.Rejected: 'Rejected',
  DepositStatusEnum.InProcess: 'InProcess',
  DepositStatusEnum.Completed: 'Completed',
  DepositStatusEnum.Cancelled: 'Cancelled',
};
