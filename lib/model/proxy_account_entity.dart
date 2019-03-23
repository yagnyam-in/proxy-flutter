import 'package:meta/meta.dart';
import 'package:proxy_messages/banking.dart';

class ProxyAccountEntity {
  final ProxyAccountId accountId;
  final Amount balance;
  final String accountName;
  final String bankName;
  final String signedProxyAccount;

  ProxyAccountEntity({
    @required this.accountId,
    @required this.accountName,
    @required this.bankName,
    @required this.balance,
    @required this.signedProxyAccount,
  });
}
