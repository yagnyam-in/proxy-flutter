import 'package:proxy_core/core.dart';
import 'package:promo/banking/model/receiving_account_entity.dart';
import 'package:proxy_messages/banking.dart';
import 'package:uuid/uuid.dart';

class TestReceivingAccounts {
  static final Uuid uuidFactory = Uuid();

  static ReceivingAccountEntity get immediateSuccessfulAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      internalId: "inr-immediate-success",
      currency: Currency.INR,
      accountName: 'Success',
      accountNumber: '026291800001191',
      accountHolder: 'Success',
      bankName: 'Yes Bank',
      ifscCode: 'YESB0000262',
      email: 'good@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get immediateFailureAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      internalId: "inr-immediate-failure",
      currency: Currency.INR,
      accountName: 'Immediate Failure',
      accountNumber: '026291800001190',
      accountHolder: 'Immediate Failure',
      bankName: 'Yes Bank',
      ifscCode: 'YESB0000262',
      email: 'bad@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get eventualSuccessfulAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      internalId: "inr-eventual-success",
      currency: Currency.INR,
      accountName: 'Eventually Success',
      accountNumber: '00224412311300',
      accountHolder: 'Eventually Success',
      bankName: 'Yes Bank',
      ifscCode: 'YESB0000001',
      email: 'ugly@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get eventualFailureAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      internalId: "inr-eventual-failure",
      currency: Currency.INR,
      accountName: 'Eventually Failure',
      accountNumber: '7766666351000',
      accountHolder: 'Eventually Failure',
      bankName: 'Yes Bank',
      ifscCode: 'YESB0000001',
      email: 'bad@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get bunqAccountForEUR {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      currency: Currency.EUR,
      internalId: "eur-bunq",
      accountName: 'Bunq Account',
      accountNumber: 'NL07BUNQ9900247515',
      accountHolder: 'Laura Hardy',
      bankName: 'Bunq',
    );
  }

  static List<ReceivingAccountEntity> get allTestAccounts => [
        immediateSuccessfulAccountForInr,
        immediateFailureAccountForInr,
        eventualSuccessfulAccountForInr,
        eventualFailureAccountForInr,
        bunqAccountForEUR
      ];
}
