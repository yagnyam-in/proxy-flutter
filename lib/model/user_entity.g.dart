// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserEntity _$UserEntityFromJson(Map json) {
  return UserEntity(
    uid: json['uid'] as String,
    accountId: json['accountId'] as String,
    masterProxyId: json['masterProxyId'] == null
        ? null
        : ProxyId.fromJson(json['masterProxyId'] as Map),
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
    address: json['address'] as String,
  );
}

Map<String, dynamic> _$UserEntityToJson(UserEntity instance) {
  final val = <String, dynamic>{
    'uid': instance.uid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('accountId', instance.accountId);
  writeNotNull('masterProxyId', instance.masterProxyId?.toJson());
  writeNotNull('name', instance.name);
  writeNotNull('phone', instance.phone);
  writeNotNull('email', instance.email);
  writeNotNull('address', instance.address);
  return val;
}
