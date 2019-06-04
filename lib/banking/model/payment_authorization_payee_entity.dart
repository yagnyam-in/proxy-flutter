import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';


class PaymentAuthorizationPayeeEntity {
  final int id;
  final PayeeTypeEnum payeeType;
  final ProxyId proxyId;
  final String email;
  final String phone;
  final String secret;
  final String emailHash;
  final String phoneHash;
  final String secretHash;
  final String proxyUniverse;
  final String paymentAuthorizationId;
  final String paymentEncashmentId;

  PaymentAuthorizationPayeeEntity({
    this.id,
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
}
