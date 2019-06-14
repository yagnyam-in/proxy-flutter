import 'dart:core';

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'proxy_entity.g.dart';

@JsonSerializable()
class ProxyEntity {
  @JsonKey(nullable: false)
  final ProxyId proxyId;

  @JsonKey(nullable: false)
  final Proxy proxy;

  @JsonKey(nullable: false)
  final DateTime lastUpdated;

  ProxyEntity({
    @required this.proxyId,
    @required this.proxy,
    DateTime lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  ProxyEntity.fromProxy(Proxy proxy)
      : proxy = proxy,
        proxyId = proxy.id,
        lastUpdated = DateTime.now();

  Map<String, dynamic> toJson() => _$ProxyEntityToJson(this);

  static ProxyEntity fromJson(Map json) => _$ProxyEntityFromJson(json);
}
