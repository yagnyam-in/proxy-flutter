import 'dart:async';

import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/receiving_account_entity.dart';

class ReceivingAccountRepo {
  final DB db;

  ReceivingAccountRepo._instance(this.db);

  factory ReceivingAccountRepo.instance(DB database) =>
      ReceivingAccountRepo._instance(database);

  Future<List<ReceivingAccountEntity>> fetchAccountsForCurrency(
      String currency) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
      where: '$CURRENCY = ? AND $ACTIVE = 1',
      whereArgs: [currency],
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
      ACCOUNT_NAME: entity.accountName,
      ACCOUNT_NUMBER: entity.accountNumber,
      ACCOUNT_HOLDER: entity.accountHolder,
      BANK: entity.bank,
      CURRENCY: entity.currency,
      IFSC_CODE: entity.ifscCode,
      ACTIVE: entity.active ? 1 : 0,
    };
  }

  static ReceivingAccountEntity _mapToEntity(Map<dynamic, dynamic> map) {
    return ReceivingAccountEntity(
      id: map[ID],
      accountName: map[ACCOUNT_NAME],
      accountNumber: map[ACCOUNT_NUMBER],
      accountHolder: map[ACCOUNT_HOLDER],
      bank: map[BANK],
      currency: map[CURRENCY],
      ifscCode: map[IFSC_CODE],
      active: map[ACTIVE] != 0,
    );
  }

  static const String TABLE = "RECEIVING_ACCOUNT";
  static const String ID = "id";
  static const String ACCOUNT_NAME = "accountName";
  static const String ACCOUNT_NUMBER = "accountNumber";
  static const String ACCOUNT_HOLDER = "accountHolder";
  static const String BANK = "bank";
  static const String CURRENCY = "currency";
  static const String IFSC_CODE = "ifscCode";
  static const String ACTIVE = "active";

  static const ALL_COLUMNS = [
    ID,
    ACCOUNT_NAME,
    ACCOUNT_NUMBER,
    ACCOUNT_HOLDER,
    BANK,
    CURRENCY,
    IFSC_CODE,
    ACTIVE
  ];

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ('
        '$ID INTEGER PRIMARY KEY, '
        '$ACCOUNT_NAME TEXT, '
        '$ACCOUNT_NUMBER TEXT, '
        '$ACCOUNT_HOLDER TEXT, '
        '$BANK TEXT, '
        '$CURRENCY TEXT, '
        '$IFSC_CODE TEXT, '
        '$ACTIVE INTEGER)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
