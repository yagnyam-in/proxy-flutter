// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_account_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyAccountEntity _$ProxyAccountEntityFromJson(Map json) {
  return ProxyAccountEntity(
    internalId: json['internalId'] as String,
    proxyUniverse: json['proxyUniverse'] as String,
    proxyAccountId: ProxyAccountId.fromJson(json['proxyAccountId'] as Map),
    accountName: json['accountName'] as String,
    bankName: json['bankName'] as String,
    balance: Amount.fromJson(json['balance'] as Map),
    ownerProxyId: ProxyId.fromJson(json['ownerProxyId'] as Map),
    signedProxyAccount:
        ProxyAccount.signedMessageFromJson(json['signedProxyAccount'] as Map),
    currency: json['currency'] as String,
    active: json['active'] as bool,
    bankId: json['bankId'] as String,
    accountId: json['accountId'] as String,
  );
}

Map<String, dynamic> _$ProxyAccountEntityToJson(ProxyAccountEntity instance) {
  final val = <String, dynamic>{
    'internalId': instance.internalId,
    'proxyUniverse': instance.proxyUniverse,
    'proxyAccountId': instance.proxyAccountId.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('accountId', instance.accountId);
  writeNotNull('bankId', instance.bankId);
  writeNotNull('accountName', instance.accountName);
  writeNotNull('bankName', instance.bankName);
  val['ownerProxyId'] = instance.ownerProxyId.toJson();
  val['balance'] = instance.balance.toJson();
  val['signedProxyAccount'] = instance.signedProxyAccount.toJson();
  val['active'] = instance.active;
  val['currency'] = instance.currency;
  return val;
}
