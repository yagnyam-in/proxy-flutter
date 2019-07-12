import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';

part 'proxy_account_entity.g.dart';

@JsonSerializable()
class ProxyAccountEntity with ProxyUtils {
  static const String CURRENCY = 'currency';
  static const String ACTIVE = 'active';
  static const String ID_OF_OWNER_PROXY_ID = 'idOfOwnerProxyId';

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

  @JsonKey(name: ACTIVE, nullable: false)
  final bool active;

  @JsonKey(name: CURRENCY, nullable: false)
  final String currency;

  @JsonKey(name: ID_OF_OWNER_PROXY_ID, nullable: false)
  final String idOfOwnerProxyId;

  String get validAccountName => isNotEmpty(accountName) ? accountName : accountId.accountId;

  String get validBankName => isNotEmpty(bankName) ? bankName : accountId.bankId;

  String get proxyUniverse => accountId.proxyUniverse;

  ProxyAccountEntity({
    @required this.accountId,
    @required this.accountName,
    @required this.bankName,
    @required this.balance,
    @required this.ownerProxyId,
    @required this.signedProxyAccount,
    String idOfOwnerProxyId,
    String currency,
    bool active,
  }) : this.active = active ?? true, this.currency = balance.currency, this.idOfOwnerProxyId = ownerProxyId.id {
    assert(currency == null || this.currency == currency);
    assert(idOfOwnerProxyId == null || this.idOfOwnerProxyId == idOfOwnerProxyId);
  }

  ProxyAccountEntity copy({
    Amount balance,
    String accountName,
    String bankName,
    bool active,
  }) {
    return ProxyAccountEntity(
      accountId: this.accountId,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      ownerProxyId: this.ownerProxyId,
      signedProxyAccount: this.signedProxyAccount,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => _$ProxyAccountEntityToJson(this);

  static ProxyAccountEntity fromJson(Map json) => _$ProxyAccountEntityFromJson(json);
}
