import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';


enum EventType { Unknown, Deposit, Withdraw, Payment, Fx }

class EventAction {
  final String title;
  final IconData icon;
  final FutureCallback action;

  EventAction(
      {@required this.title, @required this.icon, @required this.action});
}

abstract class EventEntity {
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ID = "id";
  static const String EVENT_TYPE = "eventType";
  static const String EVENT_ID = "eventId";
  static const String STATUS = "status";
  static const String COMPLETED = "completed";
  static const String CREATION_TIME = "creationTime";
  static const String LAST_UPDATED_TIME = "lastUpdatedTime";

  static const String DEPOSIT_STATUS = "depositStatus";
  static const String DEPOSIT_AMOUNT_CURRENCY = "depositAmountCurrency";
  static const String DEPOSIT_AMOUNT_VALUE = "depositAmountValue";
  static const String DEPOSIT_DESTINATION_PROXY_ACCOUNT_ID = "depositDestProxyAccountId";
  static const String DEPOSIT_DESTINATION_PROXY_ACCOUNT_BANK_ID = "depositDestProxyAccountBankId";
  static const String DEPOSIT_LINK= "depositLink";

  static const String WITHDRAWAL_STATUS = "withdrawalStatus";
  static const String WITHDRAWAL_AMOUNT_CURRENCY = "withdrawalAmountCurrency";
  static const String WITHDRAWAL_AMOUNT_VALUE = "withdrawalAmountValue";
  static const String WITHDRAWAL_DESTINATION_ACCOUNT_NUMBER = "withdrawalDestAccountNumber";
  static const String WITHDRAWAL_DESTINATION_ACCOUNT_BANK = "withdrawalDestAccountBank";


  final int id;

  @JsonKey(nullable: false)
  final String proxyUniverse;

  @JsonKey(nullable: false)
  final EventType eventType;

  @JsonKey(nullable: false)
  final String eventId;

  @JsonKey(nullable: false)
  final DateTime creationTime;

  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;

  @JsonKey(nullable: false)
  final bool completed;

  EventEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.eventType,
    @required this.eventId,
    @required bool completed,
  }) : completed = completed ?? false;

  @mustCallSuper
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = {
      PROXY_UNIVERSE: proxyUniverse,
      EVENT_TYPE: eventTypeToString(eventType),
      EVENT_ID: eventId,
      COMPLETED: completed ? 1 : 0,
      CREATION_TIME: ConversionUtils.dateTimeToInt(creationTime),
      LAST_UPDATED_TIME: ConversionUtils.dateTimeToInt(lastUpdatedTime),
    };
    if (id != null) {
      row[ID] = id;
    }
    return row;
  }

  EventEntity.fromRow(Map<dynamic, dynamic> row)
      : id = row[ID],
        proxyUniverse = row[PROXY_UNIVERSE],
        eventType = stringToEventType(row[EVENT_TYPE]),
        eventId = row[EVENT_ID],
        completed = (row[COMPLETED] as int) != 0,
        creationTime = ConversionUtils.intToDateTime(row[CREATION_TIME]),
        lastUpdatedTime =
            ConversionUtils.intToDateTime(row[LAST_UPDATED_TIME]) {
    print("Completed: $completed");
  }

  static EventType stringToEventType(String value,
      {EventType orElse = EventType.Unknown}) {
    return ConversionUtils.stringToEnum(
      value,
      orElse: EventType.Unknown,
      values: EventType.values,
      enumName: "EventType",
    );
  }

  static String eventTypeToString(EventType eventType) {
    return ConversionUtils.enumToString(
      eventType,
      enumName: "EventType",
    );
  }

  Map<String, dynamic> toJson();

  String getTitle(ProxyLocalizations localizations);

  String getSubTitle(ProxyLocalizations localizations);

  String getStatusAsText(ProxyLocalizations localizations);

  String getAmountAsText(ProxyLocalizations localizations);

  IconData icon();

  bool isCancellable();
}
