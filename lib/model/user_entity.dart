import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity {
  @JsonKey(nullable: false)
  final String id;

  @JsonKey(nullable: false)
  final String name;

  @JsonKey(nullable: false)
  final String phone;

  @JsonKey(nullable: false)
  final String email;

  @JsonKey(nullable: false)
  final String address;

  UserEntity({
    @required this.id,
    this.name,
    this.phone,
    this.email,
    this.address,
  }) {
    assert(id != null);
  }

  UserEntity copy({
    String name,
    String phone,
    String email,
    String address,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  static UserEntity fromJson(Map json) => _$UserEntityFromJson(json);

}
