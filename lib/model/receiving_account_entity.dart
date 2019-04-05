import 'package:meta/meta.dart';

class ReceivingAccountEntity {
  final int id;
  final String proxyUniverse;
  final String accountName;
  final String accountNumber;
  final String accountHolder;
  final String bank;
  final String currency;
  final String ifscCode;
  final String email;
  final String phone;
  final String address;
  bool active;

  ReceivingAccountEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.accountName,
    @required this.accountNumber,
    @required this.accountHolder,
    @required this.bank,
    @required this.currency,
    this.ifscCode,
    this.email,
    this.phone,
    this.address,
    bool active = true,
  }) : this.active = active;
}
