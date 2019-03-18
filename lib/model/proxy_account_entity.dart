
import 'package:meta/meta.dart';

class ProxyAccountEntity {
  final String accountId;
  final String accountName;
  
  final String bankId;
  final String bankName;
  
  final String currency;
  final double balance;
  
  final String signedProxyAccount;

  ProxyAccountEntity({@required this.accountId, @required this.accountName, @required this.bankId, @required this.bankName, @required this.currency, @required this.balance, @required this.signedProxyAccount});
}