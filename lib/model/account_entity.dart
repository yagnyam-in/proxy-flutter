import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

part 'account_entity.g.dart';

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
  int phoneVerificationIndex;

  @JsonKey(nullable: true)
  int emailVerificationIndex;

  AccountEntity({
    @required this.accountId,
    this.masterProxyId,
    this.name,
    @required this.encryptionKeyHash,
    this.preferredCurrency,
    this.phone,
    this.email,
    this.phoneVerificationIndex,
    this.emailVerificationIndex,
  });

  AccountEntity copy({
    ProxyId masterProxyId,
    String name,
    String preferredCurrency,
    String phone,
    String email,
    int phoneVerificationIndex,
    int emailVerificationIndex,
  }) {
    return AccountEntity(
      accountId: this.accountId,
      encryptionKeyHash: this.encryptionKeyHash,
      masterProxyId: masterProxyId ?? this.masterProxyId,
      name: name ?? this.name,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      phoneVerificationIndex: phoneVerificationIndex ?? this.phoneVerificationIndex,
      emailVerificationIndex: emailVerificationIndex ?? this.emailVerificationIndex,
    );
  }

  @override
  String toString() => toJson().toString();

  Map<String, dynamic> toJson() => _$AccountEntityToJson(this);

  static AccountEntity fromJson(Map json) => _$AccountEntityFromJson(json);
}
