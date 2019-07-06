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
  final String secret;
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
    this.secret,
    this.emailHash,
    this.phoneHash,
    this.secretHash,
  });


  Map<String, dynamic> toJson() => _$PaymentAuthorizationPayeeEntityToJson(this);

  static PaymentAuthorizationPayeeEntity fromJson(Map json) => _$PaymentAuthorizationPayeeEntityFromJson(json);
}
