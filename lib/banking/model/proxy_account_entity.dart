import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:quiver/strings.dart';

import 'abstract_entity.dart';

part 'proxy_account_entity.g.dart';

@JsonSerializable()
class ProxyAccountEntity extends AbstractEntity<ProxyAccountEntity> {
  static const CURRENCY = 'currency';
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const ACCOUNT_ID = "accountId";
  static const BANK_ID = "bankId";
  static const ACTIVE = AbstractEntity.ACTIVE;

  @JsonKey(nullable: false)
  String internalId;

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final ProxyAccountId proxyAccountId;

  @JsonKey(name: ACCOUNT_ID, nullable: true)
  final String accountId;

  @JsonKey(name: BANK_ID, nullable: true)
  final String bankId;

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

  @JsonKey(name: ACTIVE, nullable: false)
  final bool active;

  @JsonKey(name: CURRENCY, nullable: false)
  final String currency;

  String get validAccountName => isNotBlank(accountName) ? accountName : proxyAccountId.accountId;

  String get validBankName => isNotBlank(bankName) ? bankName : proxyAccountId.bankId;

  ProxyAccountEntity({
    this.internalId,
    @required this.proxyUniverse,
    @required this.proxyAccountId,
    @required this.accountName,
    @required this.bankName,
    @required this.balance,
    @required this.ownerProxyId,
    @required this.signedProxyAccount,
    String currency,
    bool active,
    String bankId,
    String accountId,
  })  : this.active = active ?? true,
        this.currency = balance.currency,
        this.bankId = proxyAccountId.bankId,
        this.accountId = proxyAccountId.accountId {
    assert(currency == null || this.currency == currency);
    assert(bankId == null || this.bankId == bankId);
    assert(accountId == null || this.accountId == accountId);
  }

  ProxyAccountEntity copy({
    Amount balance,
    String accountName,
    String bankName,
    bool active,
  }) {
    return ProxyAccountEntity(
      internalId: internalId,
      proxyUniverse: this.proxyUniverse,
      proxyAccountId: this.proxyAccountId,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      ownerProxyId: this.ownerProxyId,
      signedProxyAccount: this.signedProxyAccount,
      active: active ?? this.active,
    );
  }

  ProxyAccountEntity copyWithInternalId(String id) {
    this.internalId = id;
    return this;
  }

  @override
  String toString() {
    return "ProxyAccountEntity(account: $validAccountName, bank: $validBankName, balance: $balance, active: $active)";
  }

  @override
  Map<String, dynamic> toJson() => _$ProxyAccountEntityToJson(this);

  static ProxyAccountEntity fromJson(Map json) => _$ProxyAccountEntityFromJson(json);
}
