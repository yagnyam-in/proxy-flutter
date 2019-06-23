// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_key_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyKeyEntity _$ProxyKeyEntityFromJson(Map json) {
  return ProxyKeyEntity(
      proxyKey: ProxyKey.fromJson(json['proxyKey'] as Map),
      fcmToken: json['fcmToken'] as String);
}

Map<String, dynamic> _$ProxyKeyEntityToJson(ProxyKeyEntity instance) {
  final val = <String, dynamic>{
    'proxyKey': instance.proxyKey.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fcmToken', instance.fcmToken);
  return val;
}
