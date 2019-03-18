import 'dart:async';

import 'package:path/path.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';
import 'package:sqflite/sqflite.dart';

Database _database;



class DB {
  final Future<Database> _db;

  DB(this._db);

  factory DB.instance() {
    return DB(database());
  }

  Future<void> execute(String sql, [List arguments]) async {
    Database db = await _db;
    return db.execute(sql, arguments);
  }

  Future<int> insert(String table, Map<String, dynamic> values,
      {String nullColumnHack, ConflictAlgorithm conflictAlgorithm}) async {
    Database db = await _db;
    return db.insert(table, values, nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
  }

  Future<T> transaction<T>(Future<T> action(Transaction txn), {bool exclusive}) async {
    Database db = await _db;
    return db.transaction(action, exclusive: exclusive);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {bool distinct,
      List<String> columns,
      String where,
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) async {
    Database db = await _db;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Database> _openDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'proxy.db');
    return openDatabase(path, version: 1, onCreate: onCreate, onUpgrade: onUpgrade);
  }

  static Future<Database> database() async {
    if (_database == null) {
      _database = await _openDatabase();
    }
    return _database;
  }

  static Future<void> onCreate(Database database, int version) async {
    DB db = DB(Future.value(database));
    await ProxyRepo.onCreate(db, version);
    await ProxyKeyRepo.onCreate(db, version);
    await ProxyAccountRepo.onCreate(db, version);
    await EnticementRepo.onCreate(db, version);
  }

  static Future<void> onUpgrade(Database database, int oldVersion, int newVersion) async {
    DB db = DB(Future.value(database));
    await ProxyRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyKeyRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyAccountRepo.onUpgrade(db, oldVersion, newVersion);
    await EnticementRepo.onUpgrade(db, oldVersion, newVersion);
  }


}
