import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:promo/localizations.dart';
import 'package:promo/widgets/basic_types.dart';

import 'abstract_entity.dart';

enum EventType { Unknown, Deposit, Withdrawal, PaymentAuthorization, PaymentEncashment, Fx }

class EventAction {
  final String title;
  final IconData icon;
  final FutureCallback action;

  EventAction({@required this.title, @required this.icon, @required this.action});
}

abstract class EventEntity extends AbstractEntity<EventEntity> {
  static const PROXY_UNIVERSE = "proxyUniverse";
  static const EVENT_TYPE = "eventType";
  static const ACTIVE = AbstractEntity.ACTIVE;

  @JsonKey(name: PROXY_UNIVERSE, nullable: false)
  final String proxyUniverse;

  @JsonKey(name: EVENT_TYPE, nullable: false)
  final EventType eventType;

  @JsonKey(nullable: false)
  String internalId;

  @JsonKey(nullable: false)
  final String actualEventInternalId;

  @JsonKey(nullable: false)
  final DateTime creationTime;

  @JsonKey(nullable: false)
  final DateTime lastUpdatedTime;

  @JsonKey(nullable: false)
  final bool completed;

  @JsonKey(name: ACTIVE, nullable: false)
  final bool active;

  EventEntity({
    @required this.actualEventInternalId,
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.eventType,
    @required this.internalId,
    @required bool completed,
    @required bool active,
  })  : completed = completed ?? false,
        this.active = active ?? true;

  Map<String, dynamic> toJson();

  String getTitle(ProxyLocalizations localizations);

  String getSubTitle(ProxyLocalizations localizations);

  String getStatusAsText(ProxyLocalizations localizations);

  String getAmountAsText(ProxyLocalizations localizations);

  IconData icon();

  bool isCancellable();

  @override
  EventEntity copyWithInternalId(String id) {
    this.internalId = id;
    return this;
  }

  @override
  String toString() {
    return "$runtimeType(internalId: $internalId, eventType: $eventType, actualEventInternalId: $actualEventInternalId, completed: $completed)";
  }
}
