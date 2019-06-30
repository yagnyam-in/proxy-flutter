import 'package:json_annotation/json_annotation.dart';
import 'package:proxy_core/core.dart';

part 'account_entity.g.dart';

@JsonSerializable()
class AccountEntity {

  @JsonKey(nullable: false)
  final String accountId;

  @JsonKey(nullable: false)
  final String accountIdHmac;

  @JsonKey(nullable: true)
  final ProxyId masterProxyId;

  @JsonKey(nullable: true)
  final String name;

  AccountEntity({
    this.accountId,
    this.masterProxyId,
    this.name,
    this.accountIdHmac,
  });

  AccountEntity copy({
    ProxyId masterProxyId,
    String name,
  }) {
    return AccountEntity(
      accountId: this.accountId,
      accountIdHmac: this.accountIdHmac,
      masterProxyId: masterProxyId ?? this.masterProxyId,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => toJson().toString();

  Map<String, dynamic> toJson() => _$AccountEntityToJson(this);

  static AccountEntity fromJson(Map json) => _$AccountEntityFromJson(json);
}
