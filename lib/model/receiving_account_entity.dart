import 'package:meta/meta.dart';

class ReceivingAccountEntity {
  final int id;
  final String accountName;
  final String accountNumber;
  final String accountHolder;
  final String bank;
  final String currency;
  final String ifscCode;
  bool active;

  ReceivingAccountEntity({
    int id,
    @required this.accountName,
    @required this.accountNumber,
    @required this.accountHolder,
    @required this.bank,
    @required this.currency,
    String ifscCode,
    bool active = true,
  })  : this.id = id, this.ifscCode = ifscCode, this.active = active;
}
