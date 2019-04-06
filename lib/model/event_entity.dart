import 'package:meta/meta.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';

import '../localizations.dart';

enum EventType { Unknown, Deposit, Withdraw, Payment, Fx }

abstract class EventEntity {
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ID = "id";
  static const String EVENT_TYPE = "eventType";
  static const String EVENT_ID = "eventId";
  static const String STATUS = "status";
  static const String COMPLETED = "completed";
  static const String CREATION_TIME = "creationTime";
  static const String LAST_UPDATED_TIME = "lastUpdatedTime";

  static const String PRIMARY_AMOUNT = "primaryAmount";
  static const String PRIMARY_AMOUNT_CURRENCY = "primaryCurrency";

  static const String PAYER_PROXY_ID = "payerProxyId";
  static const String PAYER_PROXY_SHA = "payerProxySha";

  static const String PAYER_PROXY_ACCOUNT_ID = "payerProxyAccountId";
  static const String PAYER_PROXY_ACCOUNT_BANK_ID = "payerProxyAccountBankId";

  static const String PAYEE_ACCOUNT_NUMBER = "payeeAccountNumber";
  static const String PAYEE_ACCOUNT_BANK = "payeeAccountBank";

  static const String SIGNED_REQUEST = "signedRequest";

  final int id;
  final String proxyUniverse;
  final EventType eventType;
  final String eventId;
  final DateTime creationTime;
  DateTime lastUpdatedTime;
  bool completed;

  EventEntity({
    this.id,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.eventType,
    @required this.eventId,
    bool completed,
  }) : completed = completed ?? false;

  @mustCallSuper
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = {
      PROXY_UNIVERSE: proxyUniverse,
      EVENT_TYPE: eventTypeToString(eventType),
      EVENT_ID: eventId,
      COMPLETED: completed ? 1 : 0,
      CREATION_TIME: creationTime.toUtc().millisecondsSinceEpoch,
      LAST_UPDATED_TIME: lastUpdatedTime.toUtc().millisecondsSinceEpoch,
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
        creationTime = DateTime.fromMillisecondsSinceEpoch(row[CREATION_TIME] as int).toLocal(),
        lastUpdatedTime = DateTime.fromMillisecondsSinceEpoch(row[LAST_UPDATED_TIME] as int).toLocal() {
    print("Completed: $completed");
  }

  static EventType stringToEventType(String value, {EventType orElse = EventType.Unknown}) {
    return EventType.values
        .firstWhere((e) => ConversionUtils.isEnumEqual(e, value, enumName: "EventType"), orElse: () => orElse);
  }

  static String eventTypeToString(EventType eventType) {
    return eventType?.toString()?.replaceFirst("EventType.", "")?.toLowerCase();
  }


  String getTitle(ProxyLocalizations localizations);

  String getSubTitle(ProxyLocalizations localizations);

  String getSuffix(ProxyLocalizations localizations);

}
