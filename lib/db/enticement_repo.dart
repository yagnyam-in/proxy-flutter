import 'dart:async';

import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';
import 'package:sqflite/sqflite.dart';

class EnticementRepo {
  final DB db;

  EnticementRepo._internal(this.db);

  factory EnticementRepo.instance(DB database) =>
      EnticementRepo._internal(database);

  static const START = "start";
  static const LOAD_MONEY = "loadMoney";
  static const SETUP_BUNQ_ACCOUNT = "setupBunqAccount";

  Future<List<EnticementEntity>> fetchActiveEnticements() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ID, ACTIVE],
      where: '$ACTIVE = ?',
      whereArgs: [1],
    );
    return rows.map((row) => _rowToEnticementEntity(row)).toList();
  }

  EnticementEntity _rowToEnticementEntity(Map<dynamic, dynamic> row) {
    return EnticementEntity(
      enticementId: row[ID],
      priority: row[PRIORITY],
      active: row[ACTIVE] != 0,
    );
  }

  static Future<int> _dismissEnticementInTransaction(
      Transaction transaction, String enticementId) {
    Map<String, dynamic> map = {
      ID: enticementId,
      ACTIVE: 0,
    };
    return transaction.update(
      TABLE,
      map,
      where: '$ID = ?',
      whereArgs: [enticementId],
    );
  }

  Future<int> dismissEnticement(String enticementId) {
    return db.transaction((transaction) =>
        _dismissEnticementInTransaction(transaction, enticementId));
  }

  static const String TABLE = "ENTICEMENT";
  static const String ID = "id";
  static const String PRIORITY = "priority";
  static const String ACTIVE = "active";

  static Future<void> onCreate(DB db, int version) async {
    await db.createTable(
      table: TABLE,
      primaryKey: ID,
      textColumns: {ID},
      integerColumns: {PRIORITY, ACTIVE},
    );
    await db.insert(TABLE, {ID: START, PRIORITY: 100, ACTIVE: 1});
    await db.insert(TABLE, {ID: LOAD_MONEY, PRIORITY: 200, ACTIVE: 1});
    await db.insert(TABLE, {ID: SETUP_BUNQ_ACCOUNT, PRIORITY: 300, ACTIVE: 1});
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
