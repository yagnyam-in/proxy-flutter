// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_key_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyKeyEntity _$ProxyKeyEntityFromJson(Map json) {
  return ProxyKeyEntity(
      id: ProxyId.fromJson(json['id'] as Map),
      name: json['name'] as String,
      localAlias: json['localAlias'] as String,
      encryptionAlgorithm: json['encryptionAlgorithm'] as String,
      encryptedPrivateKeyEncoded: json['encryptedPrivateKeyEncoded'] as String,
      privateKeySha256Thumbprint: json['privateKeySha256Thumbprint'] as String,
      publicKeyEncoded: json['publicKeyEncoded'] as String,
      publicKeySha256Thumbprint: json['publicKeySha256Thumbprint'] as String,
      fcmToken: json['fcmToken'] as String);
}

Map<String, dynamic> _$ProxyKeyEntityToJson(ProxyKeyEntity instance) {
  final val = <String, dynamic>{
    'id': instance.id.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  val['localAlias'] = instance.localAlias;
  val['encryptionAlgorithm'] = instance.encryptionAlgorithm;
  val['encryptedPrivateKeyEncoded'] = instance.encryptedPrivateKeyEncoded;
  writeNotNull(
      'privateKeySha256Thumbprint', instance.privateKeySha256Thumbprint);
  val['publicKeyEncoded'] = instance.publicKeyEncoded;
  val['publicKeySha256Thumbprint'] = instance.publicKeySha256Thumbprint;
  writeNotNull('fcmToken', instance.fcmToken);
  return val;
}
