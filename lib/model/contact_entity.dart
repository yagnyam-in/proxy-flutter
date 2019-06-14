import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'contact_entity.g.dart';

@JsonSerializable()
class ContactEntity {

  @JsonKey(nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final ProxyId proxyId;

  @JsonKey(nullable: false)
  final String phone;

  @JsonKey(nullable: false)
  final String email;

  @JsonKey(nullable: false)
  final String name;

  ContactEntity({
    @required this.proxyId,
    this.proxyUniverse,
    this.name,
    this.phone,
    this.email,
  });

  ContactEntity copy({
    String proxyUniverse,
    String phone,
    String email,
    String name,
  }) {
    return ContactEntity(
      proxyId: this.proxyId,
      proxyUniverse: proxyUniverse ?? this.proxyUniverse,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }


  Map<String, dynamic> toJson() => _$ContactEntityToJson(this);

  static ContactEntity fromJson(Map json) => _$ContactEntityFromJson(json);

}
