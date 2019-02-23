import 'dart:async';
import 'dart:convert';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:sqflite/sqflite.dart';

class ProxyRepo {
  final DB db;

  ProxyRepo(this.db);

  factory ProxyRepo.instance(DB database) {
    return ProxyRepo(database);
  }

  Future<Proxy> fetchProxy(ProxyId proxyId) async {
    List<Map> maps = await db.query(
      TABLE,
      columns: [ID, SHA_256, PROXY],
      where: '$ID = ? AND $SHA_256 = ?',
      whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
    );
    if (maps.isNotEmpty) {
      return Proxy.fromJson(jsonDecode(maps.first[PROXY]));
    }
    return Future.value(null);
  }
  
  static Future<int> insert(Transaction transaction, Proxy proxy) {
    return transaction.insert(TABLE, {
      ID: proxy.id.id,
      SHA_256: proxy.id.sha256Thumbprint,
      PROXY: jsonEncode(proxy.toJson()),
    });
  }

  static const String TABLE = "PROXY";
  static const String ID = "id";
  static const String SHA_256 = "sha256";
  static const String PROXY = "proxy";

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ($ID TEXT PRIMARY KEY, $SHA_256 TEXT, $PROXY TEXT)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
