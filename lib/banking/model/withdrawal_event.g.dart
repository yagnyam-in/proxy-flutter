// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalEvent _$WithdrawalEventFromJson(Map json) {
  return WithdrawalEvent(
      eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
      id: json['id'] as int,
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      withdrawalId: json['withdrawalId'] as String,
      completed: json['completed'] as bool,
      status: _$enumDecode(_$WithdrawalStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map),
      destinationAccountNumber: json['destinationAccountNumber'] as String,
      destinationAccountBank: json['destinationAccountBank'] as String);
}

Map<String, dynamic> _$WithdrawalEventToJson(WithdrawalEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'proxyUniverse': instance.proxyUniverse,
      'eventType': _$EventTypeEnumMap[instance.eventType],
      'creationTime': instance.creationTime.toIso8601String(),
      'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
      'completed': instance.completed,
      'status': _$WithdrawalStatusEnumEnumMap[instance.status],
      'amount': instance.amount.toJson(),
      'destinationAccountNumber': instance.destinationAccountNumber,
      'destinationAccountBank': instance.destinationAccountBank,
      'withdrawalId': instance.withdrawalId
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

const _$WithdrawalStatusEnumEnumMap = <WithdrawalStatusEnum, dynamic>{
  WithdrawalStatusEnum.Created: 'Created',
  WithdrawalStatusEnum.Registered: 'Registered',
  WithdrawalStatusEnum.Rejected: 'Rejected',
  WithdrawalStatusEnum.InTransit: 'InTransit',
  WithdrawalStatusEnum.Completed: 'Completed',
  WithdrawalStatusEnum.FailedInTransit: 'FailedInTransit',
  WithdrawalStatusEnum.FailedCompleted: 'FailedCompleted'
};
