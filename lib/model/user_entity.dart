import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/utils/random_utils.dart';

part 'user_entity.g.dart';

@JsonSerializable()
class UserEntity {
  @JsonKey(nullable: false)
  final String uid;

  @JsonKey(nullable: false)
  final String password;

  @JsonKey(nullable: true)
  final String accountId;

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
    @required this.uid,
    @required this.password,
    this.accountId,
    this.masterProxyId,
    this.name,
    this.phone,
    this.email,
    this.address,
  });

  UserEntity copy({
    String accountId,
    ProxyId masterProxyId,
    String name,
    String phone,
    String email,
    String address,
  }) {
    return UserEntity(
      uid: uid,
      password: password,
      accountId: accountId ?? this.accountId,
      masterProxyId: masterProxyId ?? this.masterProxyId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return {
      uid: uid,
      accountId: accountId,
      name: name,
      phone: phone,
      email: email,
    }.toString();
  }

  Map<String, dynamic> toJson() => _$UserEntityToJson(this);

  static UserEntity fromJson(Map json) => _$UserEntityFromJson(json);

  factory UserEntity.from(FirebaseUser firebaseUser) {
    return UserEntity(
      uid: firebaseUser.uid,
      password: RandomUtils.randomSecret(32),
      name: firebaseUser.displayName == null || firebaseUser.displayName.isEmpty
          ? null
          : firebaseUser.displayName,
      phone: firebaseUser.phoneNumber,
      email: firebaseUser.email,
    );
  }
}
