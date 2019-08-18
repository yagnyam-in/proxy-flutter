// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceEntity _$DeviceEntityFromJson(Map json) {
  return DeviceEntity(
    deviceId: json['deviceId'] as String,
    fcmToken: json['fcmToken'] as String,
    proxyIdList: (json['proxyIdList'] as List)
        .map((e) => ProxyId.fromJson(e as Map))
        .toSet(),
    alertsProcessedTill: json['alertsProcessedTill'] == null
        ? null
        : DateTime.parse(json['alertsProcessedTill'] as String),
  );
}

Map<String, dynamic> _$DeviceEntityToJson(DeviceEntity instance) {
  final val = <String, dynamic>{
    'deviceId': instance.deviceId,
    'fcmToken': instance.fcmToken,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'alertsProcessedTill', instance.alertsProcessedTill?.toIso8601String());
  val['proxyIdList'] = instance.proxyIdList.map((e) => e.toJson()).toList();
  return val;
}
