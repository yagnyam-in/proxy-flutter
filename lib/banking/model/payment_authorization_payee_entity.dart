import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/payments.dart';

part 'payment_authorization_payee_entity.g.dart';

@JsonSerializable()
class PaymentAuthorizationPayeeEntity {
  @JsonKey(nullable: false)
  final PayeeTypeEnum payeeType;
  @JsonKey(nullable: false)
  final String proxyUniverse;
  @JsonKey(nullable: false)
  final String paymentAuthorizationId;
  @JsonKey(nullable: false)
  final String paymentEncashmentId;
  @JsonKey(nullable: true)
  final ProxyId proxyId;
  @JsonKey(nullable: true)
  final String email;
  @JsonKey(nullable: true)
  final String phone;
  @JsonKey(nullable: true)
  final CipherText secretEncrypted;
  @JsonKey(nullable: true)
  final HashValue emailHash;
  @JsonKey(nullable: true)
  final HashValue phoneHash;
  @JsonKey(nullable: true)
  final HashValue secretHash;
  // Don't store this
  @JsonKey(ignore: true)
  final String secret;

  PaymentAuthorizationPayeeEntity({
    @required this.payeeType,
    @required this.proxyUniverse,
    @required this.paymentAuthorizationId,
    @required this.paymentEncashmentId,
    this.proxyId,
    this.email,
    this.phone,
    this.secretEncrypted,
    this.emailHash,
    this.phoneHash,
    this.secretHash,
    this.secret,
  });

  @override
  String toString() {
    return {
      'proxyUniverse': proxyUniverse,
      'paymentAuthorizationId': paymentAuthorizationId,
      'paymentEncashmentId': paymentEncashmentId,
      'payeeType': payeeType,
      'proxyId': proxyId,
    }.toString();
  }

  Map<String, dynamic> toJson() => _$PaymentAuthorizationPayeeEntityToJson(this);

  static PaymentAuthorizationPayeeEntity fromJson(Map json) => _$PaymentAuthorizationPayeeEntityFromJson(json);
}
