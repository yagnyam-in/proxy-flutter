import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'bank_entity.g.dart';

@JsonSerializable()
class BankEntity with ProxyUtils {
  static const PROXY_UNIVERSE = 'proxyUniverse';
  static const BANK_ID = 'bankId';
  static const BANK_SHA256_THUMBPRINT = 'bankSha256Thumbprint';

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final ProxyId bankProxyId;

  @JsonKey(nullable: false)
  final Set<String> supportedCurrencies;

  @JsonKey(nullable: false)
  final String apiUrl;

  @JsonKey(name: BANK_ID, nullable: false)
  final String bankId;

  @JsonKey(name: BANK_SHA256_THUMBPRINT, nullable: false)
  final String bankSha256Thumbprint;

  @JsonKey(nullable: true)
  final String bankName;

  BankEntity({
    @required this.proxyUniverse,
    @required this.bankProxyId,
    @required this.bankName,
    @required this.supportedCurrencies,
    @required this.apiUrl,
  })  : bankId = bankProxyId.id,
        bankSha256Thumbprint = bankProxyId.sha256Thumbprint;

  Map<String, dynamic> toJson() => _$BankEntityToJson(this);

  static BankEntity fromJson(Map json) => _$BankEntityFromJson(json);
}
