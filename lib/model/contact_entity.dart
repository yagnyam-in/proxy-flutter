import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:quiver/strings.dart';

part 'contact_entity.g.dart';

@JsonSerializable()
class ContactEntity {
  @JsonKey(nullable: false)
  final String id;

  @JsonKey(nullable: true)
  final ProxyId proxyId;

  @JsonKey(nullable: true)
  final String phoneNumber;

  @JsonKey(nullable: true)
  final String email;

  @JsonKey(nullable: true)
  final String name;

  ContactEntity({
    @required this.id,
    this.proxyId,
    this.name,
    this.phoneNumber,
    this.email,
  });

  ContactEntity copy({
    ProxyId proxyId,
    String phone,
    String email,
    String name,
  }) {
    return ContactEntity(
      id: this.id,
      proxyId: proxyId ?? this.proxyId,
      name: name ?? this.name,
      phoneNumber: phone ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }

  bool get isUsable => (proxyId != null && proxyId.isValid()) || isNotEmpty(email) || isNotEmpty(phoneNumber);

  @override
  bool operator ==(dynamic other) {
    if (other is ContactEntity) {
      return this.id == other.id &&
          this.proxyId == other.proxyId &&
          this.phoneNumber == other.phoneNumber &&
          this.email == other.email;
    }
    return false;
  }

  @override
  int get hashCode {
    return id == null ? 0 : id.hashCode;
  }

  @override
  String toString() {
    return "ContactEntity(id: $id, proxyId: ${proxyId?.id}, name: $name, phone: $phoneNumber, email: $email)";
  }

  Map<String, dynamic> toJson() => _$ContactEntityToJson(this);

  static ContactEntity fromJson(Map json) => _$ContactEntityFromJson(json);
}
