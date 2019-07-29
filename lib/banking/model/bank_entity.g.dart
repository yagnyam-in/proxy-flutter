// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankEntity _$BankEntityFromJson(Map json) {
  return BankEntity(
    proxyUniverse: json['proxyUniverse'] as String,
    bankProxyId: ProxyId.fromJson(json['bankProxyId'] as Map),
    supportedCurrencies:
        (json['supportedCurrencies'] as List).map((e) => e as String).toSet(),
    apiUrl: json['apiUrl'] as String,
  );
}

Map<String, dynamic> _$BankEntityToJson(BankEntity instance) =>
    <String, dynamic>{
      'proxyUniverse': instance.proxyUniverse,
      'bankProxyId': instance.bankProxyId.toJson(),
      'supportedCurrencies': instance.supportedCurrencies.toList(),
      'apiUrl': instance.apiUrl,
    };
