// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_authorization_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailAuthorizationEntity _$EmailAuthorizationEntityFromJson(Map json) {
  return EmailAuthorizationEntity(
    authorizationId: json['authorizationId'] as String,
    proxyId: ProxyId.fromJson(json['proxyId'] as Map),
    email: json['email'] as String,
    challenge: EmailAuthorizationChallenge.signedMessageFromJson(
        json['challenge'] as Map),
    authorized: json['authorized'] as bool,
    verificationIndex: json['verificationIndex'] as String,
    authorization:
        EmailAuthorization.signedMessageFromJson(json['authorization'] as Map),
    validFrom: json['validFrom'] == null
        ? null
        : DateTime.parse(json['validFrom'] as String),
    validTill: json['validTill'] == null
        ? null
        : DateTime.parse(json['validTill'] as String),
  );
}

Map<String, dynamic> _$EmailAuthorizationEntityToJson(
    EmailAuthorizationEntity instance) {
  final val = <String, dynamic>{
    'authorizationId': instance.authorizationId,
    'proxyId': instance.proxyId.toJson(),
    'email': instance.email,
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
