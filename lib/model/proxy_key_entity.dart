import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'proxy_key_entity.g.dart';

@JsonSerializable()
class ProxyKeyEntity {
  @JsonKey(nullable: false)
  final ProxyKey proxyKey;

  @JsonKey(nullable: true)
  final String fcmToken;

  ProxyKeyEntity({
    @required this.proxyKey,
    this.fcmToken,
  });

  ProxyKeyEntity copy({
    String fcmToken,
  }) {
    return ProxyKeyEntity(proxyKey: proxyKey, fcmToken: fcmToken);
  }

  ProxyId get proxyId => proxyKey?.id;

  Map<String, dynamic> toJson() => _$ProxyKeyEntityToJson(this);

  static ProxyKeyEntity fromJson(Map json) => _$ProxyKeyEntityFromJson(json);
}
