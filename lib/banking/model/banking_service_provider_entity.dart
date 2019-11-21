import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

import 'abstract_entity.dart';

part 'banking_service_provider_entity.g.dart';

@JsonSerializable()
class BankingServiceProviderEntity  extends AbstractEntity<BankingServiceProviderEntity> {
  static const PROXY_UNIVERSE = 'proxyUniverse';
  static const BANK_ID = 'bankId';
  static const BANK_SHA256_THUMBPRINT = 'bankSha256Thumbprint';

  @JsonKey(nullable: false)
  final String internalId;

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

  BankingServiceProviderEntity({
    @required this.internalId,
    @required this.proxyUniverse,
    @required this.bankProxyId,
    @required this.bankName,
    @required this.supportedCurrencies,
    @required this.apiUrl,
    String bankId,
    String bankSha256Thumbprint,
  })  : bankId = bankProxyId.id,
        bankSha256Thumbprint = bankProxyId.sha256Thumbprint {
    assert(bankId == null || this.bankId == bankId);
    assert(bankSha256Thumbprint == null || this.bankSha256Thumbprint == bankSha256Thumbprint);
  }

  @override
  BankingServiceProviderEntity copyWithInternalId(String id) {
    throw "BankingServiceProviderEntity.copyWithInternalId should never be invoked";
  }

  @override
  Map<String, dynamic> toJson() => _$BankingServiceProviderEntityToJson(this);

  static BankingServiceProviderEntity fromJson(Map json) => _$BankingServiceProviderEntityFromJson(json);
}
