// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receiving_account_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivingAccountEntity _$ReceivingAccountEntityFromJson(Map json) {
  return ReceivingAccountEntity(
    proxyUniverse: json['proxyUniverse'] as String,
    currency: json['currency'] as String,
    accountId: json['accountId'] as String,
    accountName: json['accountName'] as String,
    accountNumber: json['accountNumber'] as String,
    accountHolder: json['accountHolder'] as String,
    bankName: json['bankName'] as String,
    ifscCode: json['ifscCode'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String,
    active: json['active'] as bool,
  );
}

Map<String, dynamic> _$ReceivingAccountEntityToJson(ReceivingAccountEntity instance) {
  final val = <String, dynamic>{
    'proxyUniverse': instance.proxyUniverse,
    'accountId': instance.accountId,
    'currency': instance.currency,
    'active': instance.active,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('accountName', instance.accountName);
  writeNotNull('accountNumber', instance.accountNumber);
  writeNotNull('accountHolder', instance.accountHolder);
  writeNotNull('bankName', instance.bankName);
  writeNotNull('ifscCode', instance.ifscCode);
  writeNotNull('email', instance.email);
  writeNotNull('phone', instance.phone);
  writeNotNull('address', instance.address);
  return val;
}
