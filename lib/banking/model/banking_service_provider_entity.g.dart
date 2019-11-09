// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banking_service_provider_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankingServiceProviderEntity _$BankingServiceProviderEntityFromJson(Map json) {
  return BankingServiceProviderEntity(
    internalId: json['internalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    bankProxyId: ProxyId.fromJson(json['bankProxyId'] as Map),
    bankName: json['bankName'] as String,
    supportedCurrencies:
        (json['supportedCurrencies'] as List).map((e) => e as String).toSet(),
    apiUrl: json['apiUrl'] as String,
    bankId: json['bankId'] as String,
    bankSha256Thumbprint: json['bankSha256Thumbprint'] as String,
  );
}

Map<String, dynamic> _$BankingServiceProviderEntityToJson(
    BankingServiceProviderEntity instance) {
  final val = <String, dynamic>{
    'internalId': instance.internalId,
    'proxyUniverse': instance.proxyUniverse,
    'bankProxyId': instance.bankProxyId.toJson(),
    'supportedCurrencies': instance.supportedCurrencies.toList(),
    'apiUrl': instance.apiUrl,
    'bankId': instance.bankId,
    'bankSha256Thumbprint': instance.bankSha256Thumbprint,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('bankName', instance.bankName);
  return val;
}
