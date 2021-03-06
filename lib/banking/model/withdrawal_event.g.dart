// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEvent _$WithdrawalEventFromJson(Map json) {
  return WithdrawalEvent(
    eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
    internalId: json['internalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    withdrawalInternalId: json['withdrawalInternalId'] as String,
    completed: json['completed'] as bool,
    active: json['active'] as bool,
    status: _$enumDecode(_$WithdrawalStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    destinationAccountNumber: json['destinationAccountNumber'] as String,
    destinationAccountBank: json['destinationAccountBank'] as String,
  );
}

Map<String, dynamic> _$WithdrawalEventToJson(WithdrawalEvent instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'eventType': _$EventTypeEnumMap[instance.eventType],
    'internalId': instance.internalId,
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'completed': instance.completed,
    'active': instance.active,
    'status': _$WithdrawalStatusEnumEnumMap[instance.status],
    'amount': instance.amount.toJson(),
    'destinationAccountNumber': instance.destinationAccountNumber,
    'destinationAccountBank': instance.destinationAccountBank,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('withdrawalInternalId', instance.withdrawalInternalId);
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

const _$WithdrawalStatusEnumEnumMap = {
  WithdrawalStatusEnum.Created: 'Created',
  WithdrawalStatusEnum.Registered: 'Registered',
  WithdrawalStatusEnum.Rejected: 'Rejected',
  WithdrawalStatusEnum.InTransit: 'InTransit',
  WithdrawalStatusEnum.Completed: 'Completed',
  WithdrawalStatusEnum.FailedInTransit: 'FailedInTransit',
  WithdrawalStatusEnum.FailedCompleted: 'FailedCompleted',
};
