// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationConfiguration _$ApplicationConfigurationFromJson(Map json) {
  return ApplicationConfiguration(
      proxyUniverses:
          (json['proxyUniverses'] as List).map((e) => e as String).toList(),
      appInstanceId: json['appInstanceId'] as String,
      masterProxyId: ProxyId.fromJson(json['masterProxyId'] as Map));
}

Map<String, dynamic> _$ApplicationConfigurationToJson(
        ApplicationConfiguration instance) =>
    <String, dynamic>{
      'proxyUniverses': instance.proxyUniverses,
      'masterProxyId': instance.masterProxyId.toJson(),
      'appInstanceId': instance.appInstanceId
    };
