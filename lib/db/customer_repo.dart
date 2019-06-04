import 'dart:async';

import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/customer_entity.dart';

class CustomerRepo {
  final DB db;

  CustomerRepo._instance(this.db);

  factory CustomerRepo.instance(DB database) =>
      CustomerRepo._instance(database);

  Future<CustomerEntity> fetchCustomer() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
    );
    if (rows.isNotEmpty) {
      return _mapToEntity(rows[0]);
    }
    return Future.value(null);
  }

  Future<void> saveCustomer(CustomerEntity customer) async {
    Map<String, dynamic> values = _entityToMap(customer);
    int updated = await db.update(TABLE, values);
    if (updated == 0) {
      await db.insert(TABLE, values);
    }
  }

  static Map<String, dynamic> _entityToMap(CustomerEntity entity) {
    return {
      // Ignore ID
      ID: entity.id,
      NAME: entity.name,
      PHONE: entity.phone,
      EMAIL: entity.email,
      ADDRESS: entity.address,
    };
  }

  static CustomerEntity _mapToEntity(Map<dynamic, dynamic> map) {
    return CustomerEntity(
      id: map[ID],
      name: map[NAME],
      email: map[EMAIL],
      phone: map[PHONE],
      address: map[ADDRESS],
    );
  }

  static const String TABLE = "CUSTOMER";
  static const String ID = "id";
  static const String NAME = "name";
  static const String PHONE = "phone";
  static const String EMAIL = "email";
  static const String ADDRESS = "address";

  static const ALL_COLUMNS = [ID, NAME, PHONE, EMAIL, ADDRESS];

  static Future<void> onCreate(DB db, int version) async {
    await db.createTable(
      table: TABLE,
      primaryKey: ID,
      textColumns: {ID, NAME, PHONE, EMAIL, ADDRESS},
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
