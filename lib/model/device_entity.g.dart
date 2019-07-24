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
          .toSet());
}

Map<String, dynamic> _$DeviceEntityToJson(DeviceEntity instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'fcmToken': instance.fcmToken,
      'proxyIdList': instance.proxyIdList.map((e) => e.toJson()).toList()
    };
