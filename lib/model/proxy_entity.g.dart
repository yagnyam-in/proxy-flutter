// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyEntity _$ProxyEntityFromJson(Map json) {
  return ProxyEntity(
      proxy: Proxy.fromJson(json['proxy'] as Map),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String));
}

Map<String, dynamic> _$ProxyEntityToJson(ProxyEntity instance) =>
    <String, dynamic>{
      'proxy': instance.proxy.toJson(),
      'lastUpdated': instance.lastUpdated.toIso8601String()
    };
