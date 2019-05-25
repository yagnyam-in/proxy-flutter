import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:proxy_flutter/db/contacts_repo.dart';
import 'package:proxy_flutter/db/customer_repo.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/db/event_repo.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';
import 'package:proxy_flutter/db/proxy_universe_repo.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:sqflite/sqflite.dart';

Database _database;

class DB {
  final Future<Database> _db;
  static final DB _instance = DB._internal(database());

  DB._internal(this._db);

  factory DB.instance() => _instance;

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

  /// Convenience method for updating rows in the database.
  ///
  /// Update [table] with [values], a map from column names to new column
  /// values. null is a valid value that will be translated to NULL.
  ///
  /// [where] is the optional WHERE clause to apply when updating.
  /// Passing null will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictResolver] docs for more details
  Future<int> update(String table, Map<String, dynamic> values,
      {String where, List<dynamic> whereArgs, ConflictAlgorithm conflictAlgorithm}) async {
    Database db = await _db;
    return db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
  }

  /// Convenience method for deleting rows in the database.
  ///
  /// Delete from [table]
  ///
  /// [where] is the optional WHERE clause to apply when updating. Passing null
  /// will update all rows.
  ///
  /// You may include ?s in the where clause, which will be replaced by the
  /// values from [whereArgs]
  ///
  /// [conflictAlgorithm] (optional) specifies algorithm to use in case of a
  /// conflict. See [ConflictResolver] docs for more details
  ///
  /// Returns the number of rows affected if a whereClause is passed in, 0
  /// otherwise. To remove all rows and get a count pass "1" as the
  /// whereClause.
  Future<int> delete(String table, {String where, List<dynamic> whereArgs}) async {
    Database db = await _db;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  static Future<Database> _openDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'proxy.db');
    return openDatabase(path, version: 3, onCreate: onCreate, onUpgrade: onUpgrade);
  }

  static Future<Database> database() async {
    if (_database == null) {
      _database = await _openDatabase();
    }
    return _database;
  }

  static Future<void> onCreate(Database database, int version) async {
    DB db = DB._internal(Future.value(database));
    await ProxyRepo.onCreate(db, version);
    await ProxyKeyRepo.onCreate(db, version);
    await ProxyAccountRepo.onCreate(db, version);
    await EnticementRepo.onCreate(db, version);
    await ReceivingAccountRepo.onCreate(db, version);
    await CustomerRepo.onCreate(db, version);
    await ProxyUniverseRepo.onCreate(db, version);
    await EventRepo.onCreate(db, version);
    await ContactsRepo.onCreate(db, version);
  }

  static Future<void> onUpgrade(Database database, int oldVersion, int newVersion) async {
    DB db = DB._internal(Future.value(database));
    await ProxyRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyKeyRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyAccountRepo.onUpgrade(db, oldVersion, newVersion);
    await EnticementRepo.onUpgrade(db, oldVersion, newVersion);
    await ReceivingAccountRepo.onUpgrade(db, oldVersion, newVersion);
    await CustomerRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyUniverseRepo.onUpgrade(db, oldVersion, newVersion);
    await EventRepo.onUpgrade(db, oldVersion, newVersion);
    await ContactsRepo.onUpgrade(db, oldVersion, newVersion);
  }

  Future<void> addColumn({
    @required String table,
    @required String column,
    @required String type,
  }) {
      return execute('ALTER TABLE $table ADD COLUMN $column $type');
  }
}
