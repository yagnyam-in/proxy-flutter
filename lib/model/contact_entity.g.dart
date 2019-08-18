// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactEntity _$ContactEntityFromJson(Map json) {
  return ContactEntity(
    proxyId: ProxyId.fromJson(json['proxyId'] as Map),
    proxyUniverse: json['proxyUniverse'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$ContactEntityToJson(ContactEntity instance) =>
    <String, dynamic>{
      'proxyUniverse': instance.proxyUniverse,
      'proxyId': instance.proxyId.toJson(),
      'phone': instance.phone,
      'email': instance.email,
      'name': instance.name,
    };
