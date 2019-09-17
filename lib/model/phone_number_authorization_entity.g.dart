// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_number_authorization_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneNumberAuthorizationEntity _$PhoneNumberAuthorizationEntityFromJson(
    Map json) {
  return PhoneNumberAuthorizationEntity(
    authorizationId: json['authorizationId'] as String,
    proxyId: ProxyId.fromJson(json['proxyId'] as Map),
    phoneNumber: json['phoneNumber'] as String,
    challenge: PhoneNumberAuthorizationChallenge.signedMessageFromJson(
        json['challenge'] as Map),
    authorized: json['authorized'] as bool,
    verificationIndex: json['verificationIndex'] as String,
    authorization: PhoneNumberAuthorization.signedMessageFromJson(
        json['authorization'] as Map),
    validFrom: json['validFrom'] == null
        ? null
        : DateTime.parse(json['validFrom'] as String),
    validTill: json['validTill'] == null
        ? null
        : DateTime.parse(json['validTill'] as String),
  );
}

Map<String, dynamic> _$PhoneNumberAuthorizationEntityToJson(
    PhoneNumberAuthorizationEntity instance) {
  final val = <String, dynamic>{
    'authorizationId': instance.authorizationId,
    'proxyId': instance.proxyId.toJson(),
    'phoneNumber': instance.phoneNumber,
    'challenge': instance.challenge.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('authorization', instance.authorization?.toJson());
  val['authorized'] = instance.authorized;
  writeNotNull('validFrom', instance.validFrom?.toIso8601String());
  writeNotNull('validTill', instance.validTill?.toIso8601String());
  writeNotNull('verificationIndex', instance.verificationIndex);
  return val;
}
