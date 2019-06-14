import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';
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

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic> arguments]) async {
    Database db = await _db;
    return db.rawQuery(sql, arguments);
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String where, List<dynamic> whereArgs, ConflictAlgorithm conflictAlgorithm}) async {
    Database db = await _db;
    return db.update(table, values, where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
  }

  Future<int> delete(String table, {String where, List<dynamic> whereArgs}) async {
    Database db = await _db;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  static Future<Database> _openDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'proxy.db');
    return openDatabase(path, version: 4, onCreate: onCreate, onUpgrade: onUpgrade);
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
  }

  static Future<void> onUpgrade(Database database, int oldVersion, int newVersion) async {
    DB db = DB._internal(Future.value(database));
    await ProxyRepo.onUpgrade(db, oldVersion, newVersion);
    await ProxyKeyRepo.onUpgrade(db, oldVersion, newVersion);
  }

  Future<void> addColumns({
    @required String table,
    @required Set<String> columns,
    @required String type,
  }) async {
    // Note: If table doesn't have any rows, this would be empty.
    Set<String> existingColumns = {};
    try {
      List<Map<String, dynamic>> rows = await rawQuery("SELECT * FROM $table LIMIT 1");
      existingColumns = rows.expand((m) => m.keys).toSet();
    } catch (e) {
      print('Failed to query $table to get list of columns');
    }

    // Add remaining Columns
    columns.difference(existingColumns).forEach((c) async {
      try {
        await execute('ALTER TABLE $table ADD COLUMN $c $type');
      } catch (e) {
        print('Column $c additon failed, it might already exists');
      }
    });
  }

  Future<void> addIndex({
    @required String table,
    @required List<String> columns, // This must be List to preserve order
    @required String name,
    @required bool unique,
  }) async {
    try {
      await execute("CREATE ${unique ? "UNIQUE" : ""} INDEX "
          "IF NOT EXISTS $name "
          "ON $table(${columns.join(',')})");
    } catch (e) {
      print('Index $name additon failed, it might already exists');
    }
  }

  Future<void> dropTable({
    @required String table,
  }) async {
    await execute("DROP TABLE IF EXISTS $table");
  }

  Future<void> createTable({
    @required String table,
    @required String primaryKey,
    Set<String> textColumns = const {},
    Set<String> integerColumns = const {},
    Set<String> realColumns = const {},
  }) async {
    Set<String> columns = {
      ..._columns(textColumns, type: TEXT_TYPE, primaryKey: primaryKey),
      ..._columns(integerColumns, type: INTEGER_TYPE, primaryKey: primaryKey),
      ..._columns(realColumns, type: REAL_TYPE, primaryKey: primaryKey),
    };
    String statement = "CREATE TABLE IF NOT EXISTS $table (" + columns.join(",") + ")";
    await execute(statement);
  }

  Set<String> _columns(
    Set<String> columns, {
    @required String type,
    @required String primaryKey,
  }) {
    return columns.map((c) {
      if (c == primaryKey) {
        return "$c $type PRIMARY KEY";
      } else {
        return "$c $type";
      }
    }).toSet();
  }

  static const String TEXT_TYPE = "TEXT";
  static const String REAL_TYPE = "REAL";
  static const String INTEGER_TYPE = "INTEGER";
}
