// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_authorization_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentAuthorizationEntity _$PaymentAuthorizationEntityFromJson(Map json) {
  return PaymentAuthorizationEntity(
    internalId: json['internalId'] as String,
    eventInternalId: json['eventInternalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    paymentAuthorizationId: json['paymentAuthorizationId'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    status:
        _$enumDecode(_$PaymentAuthorizationStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    payerAccountId: ProxyAccountId.fromJson(json['payerAccountId'] as Map),
    payerProxyId: ProxyId.fromJson(json['payerProxyId'] as Map),
    signedPaymentAuthorization: PaymentAuthorization.signedMessageFromJson(
        json['signedPaymentAuthorization'] as Map),
    paymentAuthorizationDynamicLink:
        json['paymentAuthorizationDynamicLink'] as String,
    paymentAuthorizationLink: json['paymentAuthorizationLink'] as String,
    payees: (json['payees'] as List)
        .map((e) => PaymentAuthorizationPayeeEntity.fromJson(e as Map))
        .toList(),
    completed: json['completed'] as bool,
    bankId: json['bankId'] as String,
  );
}

Map<String, dynamic> _$PaymentAuthorizationEntityToJson(
    PaymentAuthorizationEntity instance) {
  final val = <String, dynamic>{
    'internalId': instance.internalId,
    'eventInternalId': instance.eventInternalId,
    'proxyUniverse': instance.proxyUniverse,
    'paymentAuthorizationId': instance.paymentAuthorizationId,
    'bankId': instance.bankId,
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'status': _$PaymentAuthorizationStatusEnumEnumMap[instance.status],
    'completed': instance.completed,
    'amount': instance.amount.toJson(),
    'payerAccountId': instance.payerAccountId.toJson(),
    'payerProxyId': instance.payerProxyId.toJson(),
    'payees': instance.payees.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('paymentAuthorizationDynamicLink',
      instance.paymentAuthorizationDynamicLink);
  val['paymentAuthorizationLink'] = instance.paymentAuthorizationLink;
  val['signedPaymentAuthorization'] =
      instance.signedPaymentAuthorization.toJson();
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
