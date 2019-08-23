// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneAuthorization _$PhoneAuthorizationFromJson(Map json) {
  return PhoneAuthorization(
    phone: json['phone'] as String,
    password: json['password'] as String,
  );
}

Map<String, dynamic> _$PhoneAuthorizationToJson(PhoneAuthorization instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'password': instance.password,
    };

EmailAuthorization _$EmailAuthorizationFromJson(Map json) {
  return EmailAuthorization(
    phone: json['phone'] as String,
    password: json['password'] as String,
  );
}

Map<String, dynamic> _$EmailAuthorizationToJson(EmailAuthorization instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'password': instance.password,
    };

AccountEntity _$AccountEntityFromJson(Map json) {
  return AccountEntity(
    accountId: json['accountId'] as String,
    masterProxyId: json['masterProxyId'] == null
        ? null
        : ProxyId.fromJson(json['masterProxyId'] as Map),
    name: json['name'] as String,
    encryptionKeyHash: HashValue.fromJson(json['encryptionKeyHash'] as Map),
    preferredCurrency: json['preferredCurrency'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
  )
    ..phoneAuthorizations = (json['phoneAuthorizations'] as List)
        ?.map((e) => e == null ? null : PhoneAuthorization.fromJson(e as Map))
        ?.toList()
    ..emailAuthorizations = (json['emailAuthorizations'] as List)
        ?.map((e) => e == null ? null : EmailAuthorization.fromJson(e as Map))
        ?.toList();
}

Map<String, dynamic> _$AccountEntityToJson(AccountEntity instance) {
  final val = <String, dynamic>{
    'accountId': instance.accountId,
    'encryptionKeyHash': instance.encryptionKeyHash.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('masterProxyId', instance.masterProxyId?.toJson());
  writeNotNull('name', instance.name);
  writeNotNull('preferredCurrency', instance.preferredCurrency);
  writeNotNull('phone', instance.phone);
  writeNotNull('email', instance.email);
  writeNotNull('phoneAuthorizations',
      instance.phoneAuthorizations?.map((e) => e?.toJson())?.toList());
  writeNotNull('emailAuthorizations',
      instance.emailAuthorizations?.map((e) => e?.toJson())?.toList());
  return val;
}
