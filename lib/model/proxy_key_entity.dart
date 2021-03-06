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
  final CipherText privateKeyEncodedEncrypted;

  @JsonKey(nullable: false)
  final String privateKeySha256Thumbprint;

  @JsonKey(nullable: false)
  final String publicKeyEncoded;

  @JsonKey(nullable: false)
  final String publicKeySha256Thumbprint;

  ProxyKeyEntity({
    @required this.id,
    this.name,
    @required this.localAlias,
    @required this.privateKeyEncodedEncrypted,
    @required this.privateKeySha256Thumbprint,
    @required this.publicKeyEncoded,
    @required this.publicKeySha256Thumbprint,
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
