// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountEntity _$AccountEntityFromJson(Map json) {
  return AccountEntity(
      accountId: json['accountId'] as String,
      masterProxyId: json['masterProxyId'] == null
          ? null
          : ProxyId.fromJson(json['masterProxyId'] as Map),
      name: json['name'] as String,
      encryptionKeyHash: HashValue.fromJson(json['encryptionKeyHash'] as Map));
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
  return val;
}
