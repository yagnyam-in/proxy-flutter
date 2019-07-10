// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_account_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyAccountEntity _$ProxyAccountEntityFromJson(Map json) {
  return ProxyAccountEntity(
      accountId: ProxyAccountId.fromJson(json['accountId'] as Map),
      accountName: json['accountName'] as String,
      bankName: json['bankName'] as String,
      balance: Amount.fromJson(json['balance'] as Map),
      ownerProxyId: ProxyId.fromJson(json['ownerProxyId'] as Map),
      signedProxyAccount:
          ProxyAccount.signedMessageFromJson(json['signedProxyAccount'] as Map),
      active: json['active'] as bool);
}

Map<String, dynamic> _$ProxyAccountEntityToJson(ProxyAccountEntity instance) {
  final val = <String, dynamic>{
    'accountId': instance.accountId.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('accountName', instance.accountName);
  writeNotNull('bankName', instance.bankName);
  val['ownerProxyId'] = instance.ownerProxyId.toJson();
  val['balance'] = instance.balance.toJson();
  val['signedProxyAccount'] = instance.signedProxyAccount.toJson();
  val['active'] = instance.active;
  return val;
}
