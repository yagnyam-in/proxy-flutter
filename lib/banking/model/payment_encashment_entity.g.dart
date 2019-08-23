// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_encashment_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentEncashmentEntity _$PaymentEncashmentEntityFromJson(Map json) {
  return PaymentEncashmentEntity(
    proxyUniverse: json['proxyUniverse'] as String,
    paymentAuthorizationId: json['paymentAuthorizationId'] as String,
    paymentEncashmentId: json['paymentEncashmentId'] as String,
    creationTime: DateTime.parse(json['creationTime'] as String),
    lastUpdatedTime: DateTime.parse(json['lastUpdatedTime'] as String),
    status: _$enumDecode(_$PaymentEncashmentStatusEnumEnumMap, json['status']),
    amount: Amount.fromJson(json['amount'] as Map),
    payeeAccountId: ProxyAccountId.fromJson(json['payeeAccountId'] as Map),
    payeeProxyId: ProxyId.fromJson(json['payeeProxyId'] as Map),
    signedPaymentEncashment: PaymentEncashment.signedMessageFromJson(
        json['signedPaymentEncashment'] as Map),
    paymentAuthorizationLink: json['paymentAuthorizationLink'] as String,
    completed: json['completed'] as bool,
    secretEncrypted: json['secretEncrypted'] == null
        ? null
        : CipherText.fromJson(json['secretEncrypted'] as Map),
    email: json['email'] as String,
    phone: json['phone'] as String,
  );
}

Map<String, dynamic> _$PaymentEncashmentEntityToJson(
    PaymentEncashmentEntity instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'paymentAuthorizationId': instance.paymentAuthorizationId,
    'paymentEncashmentId': instance.paymentEncashmentId,
    'creationTime': instance.creationTime.toIso8601String(),
    'lastUpdatedTime': instance.lastUpdatedTime.toIso8601String(),
    'status': _$PaymentEncashmentStatusEnumEnumMap[instance.status],
    'completed': instance.completed,
    'amount': instance.amount.toJson(),
    'payeeAccountId': instance.payeeAccountId.toJson(),
    'payeeProxyId': instance.payeeProxyId.toJson(),
    'paymentAuthorizationLink': instance.paymentAuthorizationLink,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('secretEncrypted', instance.secretEncrypted?.toJson());
  writeNotNull('email', instance.email);
  writeNotNull('phone', instance.phone);
  val['signedPaymentEncashment'] = instance.signedPaymentEncashment.toJson();
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

const _$PaymentEncashmentStatusEnumEnumMap = {
  PaymentEncashmentStatusEnum.Created: 'Created',
  PaymentEncashmentStatusEnum.Registered: 'Registered',
  PaymentEncashmentStatusEnum.Rejected: 'Rejected',
  PaymentEncashmentStatusEnum.InsufficientFunds: 'InsufficientFunds',
  PaymentEncashmentStatusEnum.CancelledByPayer: 'CancelledByPayer',
  PaymentEncashmentStatusEnum.CancelledByPayee: 'CancelledByPayee',
  PaymentEncashmentStatusEnum.InProcess: 'InProcess',
  PaymentEncashmentStatusEnum.Processed: 'Processed',
  PaymentEncashmentStatusEnum.Expired: 'Expired',
  PaymentEncashmentStatusEnum.Error: 'Error',
};
