import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'account_entity.g.dart';

@JsonSerializable()
class PhoneAuthorization {
  @JsonKey(nullable: false)
  final String phone;

  @JsonKey(nullable: false)
  final String password;

  PhoneAuthorization({
    @required this.phone,
    @required this.password,
  });

  Map<String, dynamic> toJson() => _$PhoneAuthorizationToJson(this);

  static PhoneAuthorization fromJson(Map json) => _$PhoneAuthorizationFromJson(json);
}

@JsonSerializable()
class EmailAuthorization {
  @JsonKey(nullable: false)
  final String phone;

  @JsonKey(nullable: false)
  final String password;

  EmailAuthorization({
    @required this.phone,
    @required this.password,
  });

  Map<String, dynamic> toJson() => _$EmailAuthorizationToJson(this);

  static EmailAuthorization fromJson(Map json) => _$EmailAuthorizationFromJson(json);
}

@JsonSerializable()
class AccountEntity {
  @JsonKey(nullable: false)
  final String accountId;

  @JsonKey(nullable: false)
  final HashValue encryptionKeyHash;

  @JsonKey(nullable: true)
  final ProxyId masterProxyId;

  @JsonKey(nullable: true)
  final String name;

  @JsonKey(nullable: true)
  String preferredCurrency;

  @JsonKey(nullable: true)
  String phone;

  @JsonKey(nullable: true)
  String email;

  @JsonKey(nullable: true)
  List<PhoneAuthorization> phoneAuthorizations;

  @JsonKey(nullable: true)
  List<EmailAuthorization> emailAuthorizations;

  AccountEntity({
    @required this.accountId,
    this.masterProxyId,
    this.name,
    @required this.encryptionKeyHash,
    this.preferredCurrency,
    this.phone,
    this.email,
  });

  AccountEntity copy({
    ProxyId masterProxyId,
    String name,
    String preferredCurrency,
    String phone,
    String email,
  }) {
    return AccountEntity(
      accountId: this.accountId,
      encryptionKeyHash: this.encryptionKeyHash,
      masterProxyId: masterProxyId ?? this.masterProxyId,
      name: name ?? this.name,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  String toString() => toJson().toString();

  Map<String, dynamic> toJson() => _$AccountEntityToJson(this);

  static AccountEntity fromJson(Map json) => _$AccountEntityFromJson(json);
}
