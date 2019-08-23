// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_authorization_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentAuthorizationEvent _$PaymentAuthorizationEventFromJson(Map json) {
  return PaymentAuthorizationEvent(
    eventType: _$enumDecode(_$EventTypeEnumMap, json['eventType']),
    proxyUniverse: json['proxyUniverse'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    completed: json['completed'] as bool,
    paymentAuthorizationId: json['paymentAuthorizationId'] as String,
    status:
        _$enumDecode(_$PaymentAuthorizationStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    payerAccountId: ProxyAccountId.fromJson(json['payerAccountId'] as Map),
    paymentAuthorizationLink: json['paymentAuthorizationLink'] as String,
  );
}

Map<String, dynamic> _$PaymentAuthorizationEventToJson(
    PaymentAuthorizationEvent instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'eventType': _$EventTypeEnumMap[instance.eventType],
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'completed': instance.completed,
    'status': _$PaymentAuthorizationStatusEnumEnumMap[instance.status],
    'amount': instance.amount.toJson(),
    'payerAccountId': instance.payerAccountId.toJson(),
    'paymentAuthorizationLink': instance.paymentAuthorizationLink,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('paymentAuthorizationId', instance.paymentAuthorizationId);
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

const _$PaymentAuthorizationStatusEnumEnumMap = {
  PaymentAuthorizationStatusEnum.Created: 'Created',
  PaymentAuthorizationStatusEnum.Registered: 'Registered',
  PaymentAuthorizationStatusEnum.Rejected: 'Rejected',
  PaymentAuthorizationStatusEnum.InsufficientFunds: 'InsufficientFunds',
  PaymentAuthorizationStatusEnum.CancelledByPayer: 'CancelledByPayer',
  PaymentAuthorizationStatusEnum.CancelledByPayee: 'CancelledByPayee',
  PaymentAuthorizationStatusEnum.InProcess: 'InProcess',
  PaymentAuthorizationStatusEnum.Processed: 'Processed',
  PaymentAuthorizationStatusEnum.Expired: 'Expired',
  PaymentAuthorizationStatusEnum.Error: 'Error',
};
