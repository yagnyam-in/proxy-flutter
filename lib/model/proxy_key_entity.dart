import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'proxy_key_entity.g.dart';

@JsonSerializable()
class ProxyKeyEntity {
  @JsonKey(nullable: false)
  final ProxyId id;

  @JsonKey(nullable: true, includeIfNull: false)
  final String name;

  @JsonKey(nullable: false)
  final String localAlias;

  @JsonKey(nullable: false)
  final String encryptionAlgorithm;

  @JsonKey(nullable: false)
  final String encryptedPrivateKeyEncoded;

  @JsonKey(nullable: true)
  final String privateKeySha256Thumbprint;

  @JsonKey(nullable: false)
  final String publicKeyEncoded;

  @JsonKey(nullable: false)
  final String publicKeySha256Thumbprint;

  @JsonKey(nullable: true, includeIfNull: true)
  final String fcmToken;

  ProxyKeyEntity({
    @required this.id,
    this.name,
    @required this.localAlias,
    @required this.encryptionAlgorithm,
    @required this.encryptedPrivateKeyEncoded,
    @required this.privateKeySha256Thumbprint,
    @required this.publicKeyEncoded,
    @required this.publicKeySha256Thumbprint,
    this.fcmToken,
  });

  String toString() {
    return {
      "id": id,
      "name": name,
      "localAlias": localAlias,
    }.toString();
  }

  Map<String, dynamic> toJson() => _$ProxyKeyEntityToJson(this);

  static ProxyKeyEntity fromJson(Map json) => _$ProxyKeyEntityFromJson(json);
}
