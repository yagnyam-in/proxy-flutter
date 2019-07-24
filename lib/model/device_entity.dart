import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'device_entity.g.dart';

@JsonSerializable()
class DeviceEntity {
  @JsonKey(nullable: false)
  final String deviceId;

  @JsonKey(nullable: false)
  final String fcmToken;

  @JsonKey(nullable: false)
  final Set<ProxyId> proxyIdList;

  DeviceEntity({
    @required this.deviceId,
    @required this.fcmToken,
    @required this.proxyIdList,
  });

  String toString() {
    return {
      "deviceId": deviceId,
      "fcmToken": fcmToken,
      "proxyIdList": proxyIdList,
    }.toString();
  }

  Map<String, dynamic> toJson() => _$DeviceEntityToJson(this);

  static DeviceEntity fromJson(Map json) => _$DeviceEntityFromJson(json);
}
