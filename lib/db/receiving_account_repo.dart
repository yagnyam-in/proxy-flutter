import 'dart:async';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';
import 'package:proxy_messages/banking.dart';

class ReceivingAccountRepo {
  final DB db;

  ReceivingAccountRepo._instance(this.db);

  factory ReceivingAccountRepo.instance(DB database) => ReceivingAccountRepo._instance(database);

  Future<List<ReceivingAccountEntity>> fetchAccountsForCurrency({String proxyUniverse, String currency}) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
      where: '$CURRENCY = ? AND $PROXY_UNIVERSE = ? AND $ACTIVE = 1',
      whereArgs: [currency, proxyUniverse],
    );
    return rows.map(_mapToEntity).toList();
  }

  Future<List<ReceivingAccountEntity>> fetchAccounts() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
      where: '$ACTIVE = 1',
    );
    return rows.map(_mapToEntity).toList();
  }

  Future<int> _insert(ReceivingAccountEntity receivingAccount) {
    return db.insert(TABLE, _entityToMap(receivingAccount));
  }

  Future<int> _update(ReceivingAccountEntity receivingAccount) {
    return db.update(
      TABLE,
      _entityToMap(receivingAccount),
      where: '$ID = ?',
      whereArgs: [receivingAccount.id],
    );
  }

  Future<int> save(ReceivingAccountEntity receivingAccount) {
    if (receivingAccount.id == null || receivingAccount.id == 0) {
      return _insert(receivingAccount);
    } else {
      return _update(receivingAccount);
    }
  }

  static Map<String, dynamic> _entityToMap(ReceivingAccountEntity entity) {
    return {
      // Ignore ID
      PROXY_UNIVERSE: entity.proxyUniverse,
      ACCOUNT_NAME: entity.accountName,
      ACCOUNT_NUMBER: entity.accountNumber,
      ACCOUNT_HOLDER: entity.accountHolder,
      BANK: entity.bank,
      CURRENCY: entity.currency,
      IFSC_CODE: entity.ifscCode,
      EMAIL: entity.email,
      PHONE: entity.phone,
      ADDRESS: entity.address,
      ACTIVE: entity.active ? 1 : 0,
    };
  }

  static ReceivingAccountEntity _mapToEntity(Map<dynamic, dynamic> map) {
    return ReceivingAccountEntity(
      id: map[ID],
      proxyUniverse: map[PROXY_UNIVERSE],
      accountName: map[ACCOUNT_NAME],
      accountNumber: map[ACCOUNT_NUMBER],
      accountHolder: map[ACCOUNT_HOLDER],
      bank: map[BANK],
      currency: map[CURRENCY],
      ifscCode: map[IFSC_CODE],
      email: map[EMAIL],
      phone: map[PHONE],
      address: map[ADDRESS],
      active: map[ACTIVE] != 0,
    );
  }

  static const String TABLE = "RECEIVING_ACCOUNT";
  static const String ID = "id";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ACCOUNT_NAME = "accountName";
  static const String ACCOUNT_NUMBER = "accountNumber";
  static const String ACCOUNT_HOLDER = "accountHolder";
  static const String BANK = "bank";
  static const String CURRENCY = "currency";
  static const String IFSC_CODE = "ifscCode";
  static const String EMAIL = "email";
  static const String PHONE = "phone";
  static const String ADDRESS = "address";
  static const String ACTIVE = "active";

  static const ALL_COLUMNS = [
    ID,
    PROXY_UNIVERSE,
    ACCOUNT_NAME,
    ACCOUNT_NUMBER,
    ACCOUNT_HOLDER,
    BANK,
    CURRENCY,
    IFSC_CODE,
    EMAIL,
    PHONE,
    ADDRESS,
    ACTIVE,
  ];

  static Future<void> onCreate(DB db, int version) async {
    await db.execute('CREATE TABLE $TABLE ('
        '$ID INTEGER PRIMARY KEY, '
        '$PROXY_UNIVERSE TEXT, '
        '$ACCOUNT_NAME TEXT, '
        '$ACCOUNT_NUMBER TEXT, '
        '$ACCOUNT_HOLDER TEXT, '
        '$BANK TEXT, '
        '$CURRENCY TEXT, '
        '$IFSC_CODE TEXT, '
        '$EMAIL TEXT, '
        '$PHONE TEXT, '
        '$ADDRESS TEXT, '
        '$ACTIVE INTEGER)');
    List<ReceivingAccountEntity> testAccounts = [
      _immediateSuccessfulAccountForInr,
      _eventualSuccessfulAccountForInr,
      _eventualFailureAccountForInr,
      _immediateFailureAccountForInr,
      _bunqAccountForEUR,
    ];
    testAccounts.forEach((e) => db.insert(TABLE, _entityToMap(e)));
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }

  static ReceivingAccountEntity get _immediateSuccessfulAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      accountName: 'Success',
      accountNumber: '026291800001191',
      accountHolder: 'Success',
      bank: 'Yes Bank',
      currency: Currency.INR,
      ifscCode: 'YESB0000262',
      email: 'good@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get _immediateFailureAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      accountName: 'Immediate Failure',
      accountNumber: '026291800001190',
      accountHolder: 'Immediate Failure',
      bank: 'Yes Bank',
      currency: Currency.INR,
      ifscCode: 'YESB0000262',
      email: 'bad@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get _eventualSuccessfulAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      accountName: 'Eventually Success',
      accountNumber: '00224412311300',
      accountHolder: 'Eventually Success',
      bank: 'Yes Bank',
      currency: Currency.INR,
      ifscCode: 'YESB0000001',
      email: 'ugly@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get _eventualFailureAccountForInr {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      accountName: 'Eventually Failure',
      accountNumber: '7766666351000',
      accountHolder: 'Eventually Failure',
      bank: 'Yes Bank',
      currency: Currency.INR,
      ifscCode: 'YESB0000001',
      email: 'bad@dummy.in',
      phone: '09369939993',
      address: 'dummy',
    );
  }

  static ReceivingAccountEntity get _bunqAccountForEUR {
    return new ReceivingAccountEntity(
      proxyUniverse: ProxyUniverse.TEST,
      accountName: 'Bunq Account',
      accountNumber: 'NL07BUNQ9900247515',
      accountHolder: 'Laura Hardy',
      bank: 'Bunq',
      currency: Currency.EUR,
    );
  }
}
