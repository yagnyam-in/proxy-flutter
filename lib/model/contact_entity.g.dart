// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactEntity _$ContactEntityFromJson(Map json) {
  return ContactEntity(
    id: json['id'] as String,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$ContactEntityToJson(ContactEntity instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('phoneNumber', instance.phoneNumber);
  writeNotNull('email', instance.email);
  writeNotNull('name', instance.name);
  return val;
}
