import 'dart:async';
import 'dart:convert';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:sqflite/sqflite.dart';

class ProxyRepo {
  final DB db;

  ProxyRepo._instance(this.db);

  factory ProxyRepo.instance(DB database) => ProxyRepo._instance(database);

  Future<Proxy> fetchProxy(ProxyId proxyId) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ID, SHA_256, PROXY, LAST_ACCESSED],
      where: '$ID = ? AND $SHA_256 = ?',
      whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
    );
    if (rows.isNotEmpty) {
      updateLastAccessed(proxyId, rows.first[LAST_ACCESSED]);
      return Proxy.fromJson(jsonDecode(rows.first[PROXY]));
    }
    return null;
  }

  Future<void> updateLastAccessed(ProxyId proxyId, int lastAccessed) async {
    if (_shouldUpdateLastAccessed(lastAccessed)) {
      db.update(
        TABLE,
        {
          LAST_ACCESSED: DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: '$ID = ? AND $SHA_256 = ?',
        whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
      );
    }
  }

  bool _shouldUpdateLastAccessed(int lastAccessed) {
    if (lastAccessed == null) {
      return true;
    }
    DateTime lastAccessedDateTime =
        DateTime.fromMillisecondsSinceEpoch(lastAccessed, isUtc: true);
    if (DateTime.now().difference(lastAccessedDateTime).inDays > 1) {
      print("Need to update last Accessed");
      return true;
    }
    return false;
  }

  Future<int> insert(Proxy proxy) {
    return db.transaction((t) => insertInTransaction(t, proxy));
  }

  static Future<int> insertInTransaction(Transaction transaction, Proxy proxy) {
    return transaction.insert(TABLE, {
      ID: proxy.id.id,
      SHA_256: proxy.id.sha256Thumbprint,
      PROXY: jsonEncode(proxy.toJson()),
      LAST_ACCESSED: DateTime.now().toUtc().millisecondsSinceEpoch,
    });
  }

  static const String TABLE = "PROXY";
  static const String ID = "id";
  static const String SHA_256 = "sha256";
  static const String LAST_ACCESSED = "lastAccessed";
  static const String PROXY = "proxy";

  static Future<void> onCreate(DB db, int version) async {
    print("onCreate($version)");
    await db.createTable(
      table: TABLE,
      primaryKey: ID,
      textColumns: {ID, SHA_256, PROXY},
      integerColumns: {LAST_ACCESSED},
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    print("onUpgrade($oldVersion to $newVersion)");
    switch (oldVersion) {
      case 1:
        await db.addColumns(
          table: TABLE,
          columns: {LAST_ACCESSED},
          type: 'INTEGER',
        );
        break;
    }
  }
}
