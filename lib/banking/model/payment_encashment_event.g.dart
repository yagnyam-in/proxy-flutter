// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_encashment_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentEncashmentEvent _$PaymentEncashmentEventFromJson(Map json) {
  return PaymentEncashmentEvent(
      eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
      proxyUniverse: json['proxyUniverse'] as String,
      creationTime: DateTime.parse(json['creationTime'] as String),
      lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
      completed: json['completed'] as bool,
      paymentAuthorizationId: json['paymentAuthorizationId'] as String,
      paymentEncashmentId: json['paymentEncashmentId'] as String,
      status:
          _$enumDecode(_$PaymentEncashmentStatusEnumEnumMap, json['status']),
      amount: Amount.fromJson(json['amount'] as Map),
      payeeAccountId: ProxyAccountId.fromJson(json['payeeAccountId'] as Map),
      paymentAuthorizationLink: json['paymentAuthorizationLink'] as String);
}

Map<String, dynamic> _$PaymentEncashmentEventToJson(
    PaymentEncashmentEvent instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'eventType': _$EventTypeEnumMap[instance.eventType],
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'completed': instance.completed,
    'status': _$PaymentEncashmentStatusEnumEnumMap[instance.status],
    'amount': instance.amount.toJson(),
    'payeeAccountId': instance.payeeAccountId.toJson(),
    'paymentAuthorizationLink': instance.paymentAuthorizationLink,
    'paymentAuthorizationId': instance.paymentAuthorizationId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('paymentEncashmentId', instance.paymentEncashmentId);
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

const _$EventTypeEnumMap = <EventType, dynamic>{
  EventType.Unknown: 'Unknown',
  EventType.Deposit: 'Deposit',
  EventType.Withdrawal: 'Withdrawal',
  EventType.PaymentAuthorization: 'PaymentAuthorization',
  EventType.PaymentEncashment: 'PaymentEncashment',
  EventType.Fx: 'Fx'
};

const _$PaymentEncashmentStatusEnumEnumMap =
    <PaymentEncashmentStatusEnum, dynamic>{
  PaymentEncashmentStatusEnum.Created: 'Created',
  PaymentEncashmentStatusEnum.Registered: 'Registered',
  PaymentEncashmentStatusEnum.Rejected: 'Rejected',
  PaymentEncashmentStatusEnum.InsufficientFunds: 'InsufficientFunds',
  PaymentEncashmentStatusEnum.CancelledByPayer: 'CancelledByPayer',
  PaymentEncashmentStatusEnum.CancelledByPayee: 'CancelledByPayee',
  PaymentEncashmentStatusEnum.InProcess: 'InProcess',
  PaymentEncashmentStatusEnum.Processed: 'Processed',
  PaymentEncashmentStatusEnum.Expired: 'Expired',
  PaymentEncashmentStatusEnum.Error: 'Error'
};
