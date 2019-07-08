import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';

enum EventType { Unknown, Deposit, Withdrawal, PaymentAuthorization, PaymentEncashment, Fx }

class EventAction {
  final String title;
  final IconData icon;
  final FutureCallback action;

  EventAction({@required this.title, @required this.icon, @required this.action});
}

abstract class EventEntity {

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
    @required this.proxyUniverse,
    @required this.creationTime,
    @required this.lastUpdatedTime,
    @required this.eventType,
    @required this.eventId,
    @required bool completed,
  }) : completed = completed ?? false;

  Map<String, dynamic> toJson();

  String getTitle(ProxyLocalizations localizations);

  String getSubTitle(ProxyLocalizations localizations);

  String getStatusAsText(ProxyLocalizations localizations);

  String getAmountAsText(ProxyLocalizations localizations);

  IconData icon();

  bool isCancellable();
}
