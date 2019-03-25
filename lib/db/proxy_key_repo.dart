import 'dart:async';
import 'dart:convert';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:sqflite/sqflite.dart';

class ProxyKeyRepo {
  final DB db;

  ProxyKeyRepo._internal(this.db);

  factory ProxyKeyRepo.instance(DB database) => ProxyKeyRepo._internal(database);

  Future<ProxyKey> fetchProxy(ProxyId proxyId) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ID, SHA_256, KEY],
      where: '$ID = ? AND $SHA_256 = ?',
      whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
    );
    if (rows.isNotEmpty) {
      return ProxyKey.fromJson(jsonDecode(rows.first[KEY]));
    }
    return Future.value(null);
  }

  Future<List<ProxyKey>> fetchProxiesWithoutFcmToken(String fcmToken) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ID, SHA_256, KEY],
      where: '$FCM_TOKEN is null OR $FCM_TOKEN != ?',
      whereArgs: [fcmToken],
    );
    return rows.map((row) => ProxyKey.fromJson(jsonDecode(row[KEY]))).toList();
  }

  Future<int> updateFcmToken(ProxyId proxyId, String fcmToken) async {
    return await db.update(
      TABLE,
      {FCM_TOKEN: fcmToken},
      where: '$ID = ? AND $SHA_256 = ?',
      whereArgs: [proxyId.id, proxyId.sha256Thumbprint],
    );
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
  static const String FCM_TOKEN = "fcmToken";
  static const String KEY = "key";

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ($ID TEXT PRIMARY KEY, $SHA_256 TEXT, $FCM_TOKEN TEXT, $KEY TEXT)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
