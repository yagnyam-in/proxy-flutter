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

  final ProxyId proxyId;
  final String email;
  final String phone;
  final CipherText secretEncrypted;
  final HashValue emailHash;
  final HashValue phoneHash;
  final HashValue secretHash;

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
