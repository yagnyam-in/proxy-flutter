import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';

class ProxyAccountEntity with ProxyUtils {
  final String proxyUniverse;
  final ProxyAccountId accountId;
  final String accountName;
  final String bankName;
  final ProxyId ownerProxyId;
  final String signedProxyAccountJson;
  Amount balance;
  SignedMessage<ProxyAccount> _signedProxyAccount;

  String get validAccountName => isNotEmpty(accountName) ? accountName : accountId.accountId;

  String get validBankName => isNotEmpty(bankName) ? bankName : accountId.bankId;

  SignedMessage<ProxyAccount> get signedProxyAccount {
    if (_signedProxyAccount == null) {
      print("Constructing from $signedProxyAccountJson");
      _signedProxyAccount = MessageBuilder.instance().buildSignedMessage(signedProxyAccountJson, ProxyAccount.fromJson);
    }
    return _signedProxyAccount;
  }

  String get currency => balance?.currency;

  ProxyAccountEntity({
    @required this.proxyUniverse,
    @required this.accountId,
    @required this.accountName,
    @required this.bankName,
    @required this.balance,
    @required this.ownerProxyId,
    @required this.signedProxyAccountJson,
  });
}
