import 'dart:async';

import 'package:proxy_flutter/banking/model/deposit_event_entity.dart';
import 'package:proxy_flutter/banking/model/payment_event_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event_entity.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/event_entity.dart';

class EventRepo {
  final DB db;

  EventRepo._instance(this.db);

  factory EventRepo.instance(DB database) => EventRepo._instance(database);

  Future<EventEntity> fetchEvent(
      String proxyUniverse, EventType eventType, String eventId) async {
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
        return WithdrawalEventEntity.fromRow(row);
      case EventType.Deposit:
        return DepositEventEntity.fromRow(row);
      case EventType.Payment:
        return PaymentEventEntity.fromRow(row);
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
    EventEntity.PRIMARY_AMOUNT_CURRENCY,
    EventEntity.PAYER_PROXY_ID,
    EventEntity.PAYER_PROXY_SHA,
    EventEntity.PAYER_PROXY_ACCOUNT_ID,
    EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID,
    EventEntity.PAYEE_PROXY_ID,
    EventEntity.PAYEE_PROXY_SHA,
    EventEntity.PAYEE_PROXY_ACCOUNT_ID,
    EventEntity.PAYEE_PROXY_ACCOUNT_BANK_ID,
    EventEntity.PAYEE_ACCOUNT_NUMBER,
    EventEntity.PAYEE_ACCOUNT_BANK,
    EventEntity.DEPOSIT_LINK,
    EventEntity.SIGNED_DEPOSIT_REQUEST,
    EventEntity.SIGNED_WITHDRAWAL_REQUEST,
    EventEntity.SIGNED_PAYMENT_AUTHORIZATION_REQUEST,
    EventEntity.SIGNED_PAYMENT_ENCASHMENT_REQUEST,
    EventEntity.PAYEE_EMAIL,
    EventEntity.PAYEE_PHONE,
    EventEntity.SECRET,
    EventEntity.PAYMENT_LINK,
  };

  static const Set<String> INTEGER_COLUMNS = {
    EventEntity.ID,
    EventEntity.COMPLETED,
    EventEntity.CREATION_TIME,
    EventEntity.LAST_UPDATED_TIME,
    EventEntity.INWARD,
  };

  static const Set<String> REAL_COLUMNS = {
    EventEntity.PRIMARY_AMOUNT,
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
        await db.addColumns(
          table: TABLE,
          columns: {
            EventEntity.PAYEE_PHONE,
            EventEntity.PAYEE_EMAIL,
            EventEntity.SECRET,
            EventEntity.SIGNED_PAYMENT_ENCASHMENT_REQUEST,
            EventEntity.PAYMENT_LINK,
          },
          type: DB.TEXT_TYPE,
        );
    }
  }
}
