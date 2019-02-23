import 'dart:async';
import 'dart:convert';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:sqflite/sqflite.dart';

class ProxyKeyRepo {
  final DB db;

  ProxyKeyRepo(this.db);

  factory ProxyKeyRepo.instance(DB database) {
    return ProxyKeyRepo(database);
  }

  Future<ProxyKey> fetchProxy(ProxyId proxyId) async {
    List<Map> maps = await db.query(
      TABLE,
      columns: [ID, SHA_256, KEY],
      where: '$ID = ? AND $SHA_256 = ?',
      whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
    );
    if (maps.isNotEmpty) {
      return ProxyKey.fromJson(jsonDecode(maps.first[KEY]));
    }
    return Future.value(null);
  }
  
  static Future<int> insert(Transaction transaction, ProxyKey proxyKey) {
    return transaction.insert(TABLE, {
      ID: proxyKey.id.id,
      SHA_256: proxyKey.id.sha256Thumbprint,
      KEY: jsonEncode(proxyKey.toJson()),
    });
  }

  static const String TABLE = "PROXY_KEY";
  static const String ID = "id";
  static const String SHA_256 = "sha256";
  static const String KEY = "key";

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ($ID TEXT PRIMARY KEY, $SHA_256 TEXT, $KEY TEXT)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
