import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';

part 'proxy_account_entity.g.dart';

@JsonSerializable()
class ProxyAccountEntity with ProxyUtils {
  @JsonKey(nullable: false)
  final ProxyAccountId accountId;

  @JsonKey(nullable: true)
  final String accountName;

  @JsonKey(nullable: true)
  final String bankName;

  @JsonKey(nullable: false)
  final ProxyId ownerProxyId;

  @JsonKey(nullable: false)
  final Amount balance;

  @JsonKey(nullable: false, fromJson: ProxyAccount.signedMessageFromJson)
  final SignedMessage<ProxyAccount> signedProxyAccount;

  String get validAccountName => isNotEmpty(accountName) ? accountName : accountId.accountId;

  String get validBankName => isNotEmpty(bankName) ? bankName : accountId.bankId;

  String get currency => balance?.currency;

  String get proxyUniverse => accountId.proxyUniverse;

  ProxyAccountEntity({
    @required this.accountId,
    @required this.accountName,
    @required this.bankName,
    @required this.balance,
    @required this.ownerProxyId,
    @required this.signedProxyAccount,
  });

  ProxyAccountEntity copy({
    Amount balance,
    String accountName,
    String bankName,
  }) {
    return ProxyAccountEntity(
      accountId: accountId,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      ownerProxyId: ownerProxyId,
      signedProxyAccount: signedProxyAccount,
    );
  }

  Map<String, dynamic> toJson() => _$ProxyAccountEntityToJson(this);

  static ProxyAccountEntity fromJson(Map json) => _$ProxyAccountEntityFromJson(json);
}
