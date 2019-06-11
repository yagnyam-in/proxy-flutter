// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_authorization_payee_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentAuthorizationPayeeEntity _$PaymentAuthorizationPayeeEntityFromJson(
    Map json) {
  return PaymentAuthorizationPayeeEntity(
      payeeType: _$enumDecode(_$PayeeTypeEnumEnumMap, json['payeeType']),
      proxyUniverse: json['proxyUniverse'] as String,
      paymentAuthorizationId: json['paymentAuthorizationId'] as String,
      paymentEncashmentId: json['paymentEncashmentId'] as String,
      proxyId: json['proxyId'] == null
          ? null
          : ProxyId.fromJson(json['proxyId'] as Map),
      email: json['email'] as String,
      phone: json['phone'] as String,
      secret: json['secret'] as String,
      emailHash: json['emailHash'] as String,
      phoneHash: json['phoneHash'] as String,
      secretHash: json['secretHash'] as String);
}

Map<String, dynamic> _$PaymentAuthorizationPayeeEntityToJson(
    PaymentAuthorizationPayeeEntity instance) {
  final val = <String, dynamic>{
    'payeeType': _$PayeeTypeEnumEnumMap[instance.payeeType],
    'proxyUniverse': instance.proxyUniverse,
    'paymentAuthorizationId': instance.paymentAuthorizationId,
    'paymentEncashmentId': instance.paymentEncashmentId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('proxyId', instance.proxyId?.toJson());
  writeNotNull('email', instance.email);
  writeNotNull('phone', instance.phone);
  writeNotNull('secret', instance.secret);
  writeNotNull('emailHash', instance.emailHash);
  writeNotNull('phoneHash', instance.phoneHash);
  writeNotNull('secretHash', instance.secretHash);
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

const _$PayeeTypeEnumEnumMap = <PayeeTypeEnum, dynamic>{
  PayeeTypeEnum.ProxyId: 'ProxyId',
  PayeeTypeEnum.Email: 'Email',
  PayeeTypeEnum.Phone: 'Phone',
  PayeeTypeEnum.AnyoneWithSecret: 'AnyoneWithSecret'
};