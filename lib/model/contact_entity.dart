import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

class ContactEntity {
  final int id;

  final String proxyUniverse;

  final ProxyId proxyId;

  String name;

  ContactEntity({this.id, @required this.proxyUniverse, @required this.proxyId, @required this.name});
}
