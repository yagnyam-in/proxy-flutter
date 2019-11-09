import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'abstract_entity.dart';

part 'receiving_account_entity.g.dart';

@JsonSerializable()
class ReceivingAccountEntity extends AbstractEntity<ReceivingAccountEntity> {
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const CURRENCY = "currency";
  static const ACTIVE = AbstractEntity.ACTIVE;

  @JsonKey(nullable: false)
  String internalId;

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(name: CURRENCY, nullable: false)
  final String currency;

  @JsonKey(name: ACTIVE, nullable: false)
  final bool active;

  @JsonKey(nullable: true)
  final String accountName;

  @JsonKey(nullable: true)
  final String accountNumber;

  @JsonKey(nullable: true)
  final String accountHolder;

  @JsonKey(nullable: true)
  final String bankName;

  @JsonKey(nullable: true)
  final String ifscCode;

  @JsonKey(nullable: true)
  final String email;

  @JsonKey(nullable: true)
  final String phone;

  @JsonKey(nullable: true)
  final String address;

  ReceivingAccountEntity({
    @required this.proxyUniverse,
    @required this.currency,
    this.internalId,
    this.accountName,
    this.accountNumber,
    this.accountHolder,
    this.bankName,
    this.ifscCode,
    this.email,
    this.phone,
    this.address,
    bool active = true,
  }) : this.active = active;

  ReceivingAccountEntity copy({
    bool active,
    String accountName,
    String accountNumber,
    String accountHolder,
    String bankName,
    String ifscCode,
    String email,
    String phone,
    String address,
  }) {
    return ReceivingAccountEntity(
      proxyUniverse: proxyUniverse,
      internalId: internalId,
      currency: currency,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  ReceivingAccountEntity copyWithInternalId(String id) {
    this.internalId = id;
    return this;
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  Map<String, dynamic> toJson() => _$ReceivingAccountEntityToJson(this);

  static ReceivingAccountEntity fromJson(Map json) => _$ReceivingAccountEntityFromJson(json);
}
