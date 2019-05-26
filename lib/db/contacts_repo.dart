import 'dart:async';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:quiver/strings.dart';

class ContactsRepo {
  final DB db;

  ContactsRepo._instance(this.db);

  factory ContactsRepo.instance(DB database) =>
      ContactsRepo._instance(database);

  Future<List<ContactEntity>> fetchAllContacts() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
    );
    return rows.map(_mapToEntity).toList();
  }

  Future<ContactEntity> fetchContact(ProxyId proxyId) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
      where: isNotEmpty(proxyId.sha256Thumbprint) ? '$PROXY_ID = ? AND $PROXY_SHA_256 = ?' : '$PROXY_ID = ?',
      whereArgs: isNotEmpty(proxyId.sha256Thumbprint) ? [proxyId.id, proxyId.sha256Thumbprint] : [proxyId.id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapToEntity(rows.first);
  }

  Future<int> _insert(ContactEntity entity) {
    return db.insert(TABLE, _entityToMap(entity));
  }

  Future<int> _update(ContactEntity entity) {
    return db.update(
      TABLE,
      _entityToMap(entity),
      where: '$ID = ?',
      whereArgs: [entity.id],
    );
  }

  Future<int> save(ContactEntity entity) {
    if (entity.id == null || entity.id == 0) {
      return _insert(entity);
    } else {
      return _update(entity);
    }
  }

  Future<int> delete(ContactEntity entity) {
    if (entity.id != null) {
      return db.delete(
        TABLE,
        where: '$ID = ?',
      );
    }
    return Future.value(0);
  }

  static Map<String, dynamic> _entityToMap(ContactEntity entity) {
    return {
      // Ignore ID
      PROXY_UNIVERSE: entity.proxyUniverse,
      NAME: entity.name,
      PROXY_ID: entity.proxyId.id,
      PROXY_SHA_256: entity.proxyId.sha256Thumbprint,
      PHONE: entity.phone,
      EMAIL: entity.email,
    };
  }

  static ContactEntity _mapToEntity(Map<dynamic, dynamic> map) {
    return ContactEntity(
      id: map[ID],
      proxyUniverse: map[PROXY_UNIVERSE],
      name: map[NAME],
      proxyId: ProxyId(map[PROXY_ID], map[PROXY_SHA_256]),
      phone: map[PHONE],
      email: map[EMAIL],
    );
  }

  static const String TABLE = "CONTACT";
  static const String ID = "id";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PROXY_ID = "proxyId";
  static const String PROXY_SHA_256 = "sha256";
  static const String NAME = "name";
  static const String PHONE = "phone";
  static const String EMAIL = "email";

  static const ALL_COLUMNS = [
    ID,
    PROXY_UNIVERSE,
    PROXY_ID,
    PROXY_SHA_256,
    NAME,
    PHONE,
    EMAIL,
  ];

  static Future<void> onCreate(DB db, int version) async {
    print("onCreate($version)");
    await db.execute('CREATE TABLE IF NOT EXISTS $TABLE ('
        '$ID INTEGER PRIMARY KEY, '
        '$PROXY_UNIVERSE TEXT, '
        '$PROXY_ID TEXT, '
        '$PROXY_SHA_256 TEXT, '
        '$PHONE TEXT, '
        '$EMAIL TEXT, '
        '$NAME TEXT)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    print("onUpgrade($oldVersion to $newVersion)");
    switch (oldVersion) {
      case 3:
        await onCreate(db, newVersion);
        break;
    }
  }
}
