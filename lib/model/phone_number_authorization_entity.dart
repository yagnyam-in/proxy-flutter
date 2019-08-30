import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/authorization.dart';

part 'phone_number_authorization_entity.g.dart';

@JsonSerializable()
class PhoneNumberAuthorizationEntity {
  @JsonKey(nullable: false)
  final String authorizationId;

  @JsonKey(nullable: false)
  final ProxyId proxyId;

  @JsonKey(nullable: false)
  final String phoneNumber;

  @JsonKey(nullable: false, fromJson: PhoneNumberAuthorizationChallenge.signedMessageFromJson)
  final SignedMessage<PhoneNumberAuthorizationChallenge> challenge;

  @JsonKey(nullable: true, fromJson: PhoneNumberAuthorization.signedMessageFromJson)
  final SignedMessage<PhoneNumberAuthorization> authorization;

  @JsonKey(nullable: false)
  final bool authorized;

  @JsonKey(nullable: true)
  final DateTime validFrom;

  @JsonKey(nullable: true)
  final DateTime validTill;

  PhoneNumberAuthorizationEntity({
    @required this.authorizationId,
    @required this.proxyId,
    @required this.phoneNumber,
    @required this.challenge,
    @required this.authorized,
    this.authorization,
    this.validFrom,
    this.validTill,
  });

  PhoneNumberAuthorizationEntity copy({
    bool authorized,
    SignedMessage<PhoneNumberAuthorization> authorization,
    DateTime validFrom,
    DateTime validTill,
  }) {
    return PhoneNumberAuthorizationEntity(
      authorizationId: authorizationId,
      proxyId: proxyId,
      phoneNumber: phoneNumber,
      challenge: challenge,
      authorized: authorized ?? this.authorized,
      authorization: authorization ?? this.authorization,
      validFrom: validFrom ?? this.validFrom,
      validTill: validTill ?? this.validTill,
    );
  }

  @override
  String toString() => "PhoneNumberAuthorizationEntity("
      "authorizationId: $authorizationId, "
      "proxyId:$proxyId, "
      "phoneNumber: $phoneNumber, "
      "authorized: $authorized, "
      "validTill: $validTill"
      ")";

  Map<String, dynamic> toJson() => _$PhoneNumberAuthorizationEntityToJson(this);

  static PhoneNumberAuthorizationEntity fromJson(Map json) => _$PhoneNumberAuthorizationEntityFromJson(json);
}
