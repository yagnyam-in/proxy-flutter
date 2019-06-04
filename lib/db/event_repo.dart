import 'dart:async';

import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/event_entity.dart';

class EventRepo {
  final DB db;

  EventRepo._instance(this.db);

  factory EventRepo.instance(DB database) => EventRepo._instance(database);

  Future<EventEntity> fetchEvent(
    String proxyUniverse,
    EventType eventType,
    String eventId,
  ) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: allColumns,
      where:
          '${EventEntity.EVENT_ID} = ? AND ${EventEntity.EVENT_TYPE} = ? AND ${EventEntity.PROXY_UNIVERSE} = ?',
      whereArgs: [
        eventId,
        EventEntity.eventTypeToString(eventType),
        proxyUniverse
      ],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapToEntity(rows[0]);
  }

  Future<List<EventEntity>> fetchActiveEvents() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: allColumns,
    );
    return rows.map(_mapToEntity).toList();
  }

  Future<void> saveEvent(EventEntity event) async {
    print(
        "Saving ${event.eventId} to DB with ${EventEntity.EVENT_ID} = ${event.eventId}"
        " AND ${EventEntity.EVENT_TYPE} = ${event.eventType}");
    Map<String, dynamic> values = event.toRow();
    int updated = await db.update(
      TABLE,
      values,
      where: '${EventEntity.EVENT_ID} = ? AND ${EventEntity.EVENT_TYPE} = ?',
      whereArgs: [
        event.eventId,
        EventEntity.eventTypeToString(event.eventType)
      ],
    );
    if (updated == 0) {
      print("Inserting ${event.eventId} to DB");
      await db.insert(TABLE, values);
    } else {
      print("Updated ${event.eventId} in DB");
    }
  }

  Future<void> deleteEvent(EventEntity event) async {
    await db.delete(
      TABLE,
      where: '${EventEntity.EVENT_ID} = ? AND ${EventEntity.EVENT_TYPE} = ?',
      whereArgs: [
        event.eventId,
        EventEntity.eventTypeToString(event.eventType)
      ],
    );
  }

  EventEntity _mapToEntity(Map<dynamic, dynamic> row) {
    EventType eventType =
        EventEntity.stringToEventType(row[EventEntity.EVENT_TYPE]);
    switch (eventType) {
      case EventType.Withdraw:
        return WithdrawalEvent.fromRow(row);
      case EventType.Deposit:
        return DepositEvent.fromRow(row);
      default:
        throw "Unknown Event Type $eventType";
    }
  }

  static const String TABLE = "EVENT";

  static const Set<String> TEXT_COLUMNS = {
    EventEntity.PROXY_UNIVERSE,
    EventEntity.EVENT_TYPE,
    EventEntity.EVENT_ID,
    EventEntity.STATUS,
    EventEntity.DEPOSIT_AMOUNT_CURRENCY,
    EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_BANK_ID,
    EventEntity.DEPOSIT_DESTINATION_PROXY_ACCOUNT_ID,
    EventEntity.DEPOSIT_LINK,
    EventEntity.DEPOSIT_STATUS,
    EventEntity.WITHDRAWAL_AMOUNT_CURRENCY,
    EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_BANK,
    EventEntity.WITHDRAWAL_DESTINATION_ACCOUNT_NUMBER,
    EventEntity.WITHDRAWAL_STATUS,
  };

  static const Set<String> INTEGER_COLUMNS = {
    EventEntity.ID,
    EventEntity.COMPLETED,
    EventEntity.CREATION_TIME,
    EventEntity.LAST_UPDATED_TIME,
  };

  static const Set<String> REAL_COLUMNS = {
    EventEntity.DEPOSIT_AMOUNT_VALUE,
    EventEntity.WITHDRAWAL_AMOUNT_VALUE,
  };

  static List<String> allColumns = [
    ...INTEGER_COLUMNS,
    ...TEXT_COLUMNS,
    ...REAL_COLUMNS,
  ];

  static Future<void> onCreate(DB db, int version) async {
    db.createTable(
      table: TABLE,
      primaryKey: EventEntity.ID,
      textColumns: TEXT_COLUMNS,
      integerColumns: INTEGER_COLUMNS,
      realColumns: REAL_COLUMNS,
    );
    db.addIndex(
      table: TABLE,
      columns: [EventEntity.EVENT_ID, EventEntity.EVENT_TYPE],
      name: 'UK_EVENTID_EVENTTYPE',
      unique: true,
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 3:
        await db.dropTable(table: TABLE);
        onCreate(db, newVersion);
    }
  }
}
