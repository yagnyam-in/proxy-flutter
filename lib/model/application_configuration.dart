import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'application_configuration.g.dart';

@JsonSerializable()
class ApplicationConfiguration with ProxyUtils {
  @JsonKey(nullable: false)
  final List<String> proxyUniverses;

  @JsonKey(nullable: false)
  final ProxyId masterProxyId;

  @JsonKey(nullable: false)
  final String appInstanceId;

  ApplicationConfiguration({
    @required this.proxyUniverses,
    @required this.appInstanceId,
    this.masterProxyId,
  });

  ApplicationConfiguration copy({
    List<String> proxyUniverses,
    ProxyId masterProxyId,
    String appInstanceId,
  }) {
    return ApplicationConfiguration(
      proxyUniverses: proxyUniverses ?? this.proxyUniverses,
      appInstanceId: appInstanceId ?? this.appInstanceId,
      masterProxyId: masterProxyId ?? this.masterProxyId,
    );
  }

  Map<String, dynamic> toJson() => _$ApplicationConfigurationToJson(this);

  static ApplicationConfiguration fromJson(Map json) => _$ApplicationConfigurationFromJson(json);
}
