import 'dart:async';

import 'package:proxy_flutter/db/db.dart';
import 'package:sqflite/sqflite.dart';

class EnticementRepo {
  final DB db;

  EnticementRepo(this.db);

  factory EnticementRepo.instance(DB database) {
    return EnticementRepo(database);
  }

  Future<Set<String>> dismissedEnticements() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ID, ACTIVE],
      where: '$ACTIVE = ?',
      whereArgs: [0],
    );
    Set<String> result = Set();
    rows.forEach((row) => result.add(row[ID]));
    return result;
  }

  static Future<int> dismissEnticement(Transaction transaction, String enticementId) {
    Map<String, dynamic> map = {
      ID: enticementId,
      ACTIVE: 0,
    };
    return transaction.update(TABLE, map).then((updated) {
      if (updated == 0) {
        return transaction.insert(TABLE, map);
      }
      return updated;
    });
  }

  static const String TABLE = "ENTICEMENT";
  static const String ID = "id";
  static const String ACTIVE = "active";

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ($ID TEXT PRIMARY KEY, $ACTIVE INTEGER)');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
