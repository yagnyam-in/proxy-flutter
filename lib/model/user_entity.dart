import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:proxy_core/core.dart';

part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity {
  @JsonKey(nullable: false)
  final String id;

  @JsonKey(nullable: true)
  final ProxyId masterProxyId;

  @JsonKey(nullable: true)
  final String name;

  @JsonKey(nullable: true)
  final String phone;

  @JsonKey(nullable: true)
  final String email;

  @JsonKey(nullable: true)
  final String address;

  UserEntity({
    @required this.id,
    this.masterProxyId,
    this.name,
    this.phone,
    this.email,
    this.address,
  }) {
    assert(id != null);
  }

  UserEntity copy({
    ProxyId masterProxyId,
    String name,
    String phone,
    String email,
    String address,
  }) {
    return UserEntity(
      id: id,
      masterProxyId: masterProxyId ?? this.masterProxyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  static UserEntity fromJson(Map json) => _$UserEntityFromJson(json);

}
