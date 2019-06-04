import 'dart:async';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/proxy_universe_entity.dart';

class ProxyUniverseRepo {
  final DB db;

  ProxyUniverseRepo._instance(this.db);

  factory ProxyUniverseRepo.instance(DB database) =>
      ProxyUniverseRepo._instance(database);

  Future<List<ProxyUniverseEntity>> fetchProxyUniverses() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
    );
    return rows.map(_mapToEntity).toList();
  }

  Future<void> saveProxyUniverse(ProxyUniverseEntity customer) async {
    Map<String, dynamic> values = _entityToMap(customer);
    int updated = await db.update(TABLE, values);
    if (updated == 0) {
      await db.insert(TABLE, values);
    }
  }

  static Map<String, dynamic> _entityToMap(ProxyUniverseEntity entity) {
    return {
      NAME: entity.name,
      ACTIVE: entity.active ? 1 : 0,
    };
  }

  static ProxyUniverseEntity _mapToEntity(Map<dynamic, dynamic> map) {
    return ProxyUniverseEntity(
      name: map[NAME],
      active: map[ACTIVE] != 1,
    );
  }

  static const String TABLE = "PROXY_UNIVERSE";
  static const String NAME = "name";
  static const String ACTIVE = "active";

  static const ALL_COLUMNS = [NAME, ACTIVE];

  static Future<void> _createTable(DB db) async {
    await db.createTable(
      table: TABLE,
      primaryKey: NAME,
      textColumns: {NAME},
      integerColumns: {ACTIVE},
    );
  }

  static Future<void> _insertAllUniverses(DB db) async {
    await db.execute(
        "INSERT OR IGNORE INTO $TABLE ($NAME, $ACTIVE) VALUES ('${ProxyUniverse.PRODUCTION}', 1)");
    await db.execute(
        "INSERT OR IGNORE INTO $TABLE ($NAME, $ACTIVE) VALUES ('${ProxyUniverse.TEST}', 1)");
  }

  static Future<void> onCreate(DB db, int version) async {
    _createTable(db);
    _insertAllUniverses(db);
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
  }
}
