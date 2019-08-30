import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/authorization.dart';

part 'email_authorization_entity.g.dart';

@JsonSerializable()
class EmailAuthorizationEntity {
  @JsonKey(nullable: false)
  final String authorizationId;

  @JsonKey(nullable: false)
  final ProxyId proxyId;

  @JsonKey(nullable: false)
  final String email;

  @JsonKey(nullable: false, fromJson: EmailAuthorizationChallenge.signedMessageFromJson)
  final SignedMessage<EmailAuthorizationChallenge> challenge;

  @JsonKey(nullable: true, fromJson: EmailAuthorization.signedMessageFromJson)
  final SignedMessage<EmailAuthorization> authorization;

  @JsonKey(nullable: false)
  final bool authorized;

  @JsonKey(nullable: true)
  final DateTime validFrom;

  @JsonKey(nullable: true)
  final DateTime validTill;

  EmailAuthorizationEntity({
    @required this.authorizationId,
    @required this.proxyId,
    @required this.email,
    @required this.challenge,
    @required this.authorized,
    this.authorization,
    this.validFrom,
    this.validTill,
  });

  EmailAuthorizationEntity copy({
    bool authorized,
    SignedMessage<EmailAuthorization> authorization,
    DateTime validFrom,
    DateTime validTill,
  }) {
    return EmailAuthorizationEntity(
      authorizationId: authorizationId,
      proxyId: proxyId,
      email: email,
      challenge: challenge,
      authorized: authorized ?? this.authorized,
      authorization: authorization ?? this.authorization,
      validFrom: validFrom ?? this.validFrom,
      validTill: validTill ?? this.validTill,
    );
  }

  @override
  String toString() => "EmailAuthorizationEntity("
      "authorizationId: $authorizationId, "
      "proxyId:$proxyId, "
      "email: $email, "
      "authorized: $authorized, "
      "validTill: $validTill"
      ")";

  Map<String, dynamic> toJson() => _$EmailAuthorizationEntityToJson(this);

  static EmailAuthorizationEntity fromJson(Map json) => _$EmailAuthorizationEntityFromJson(json);
}
