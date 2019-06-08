// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationConfiguration _$ApplicationConfigurationFromJson(
    Map<String, dynamic> json) {
  return ApplicationConfiguration(
      proxyUniverses:
          (json['proxyUniverses'] as List).map((e) => e as String).toList(),
      appInstanceId: json['appInstanceId'] as String,
      masterProxyId:
          ProxyId.fromJson(json['masterProxyId'] as Map<String, dynamic>));
}

Map<String, dynamic> _$ApplicationConfigurationToJson(
        ApplicationConfiguration instance) =>
    <String, dynamic>{
      'proxyUniverses': instance.proxyUniverses,
      'masterProxyId': instance.masterProxyId,
      'appInstanceId': instance.appInstanceId
    };
