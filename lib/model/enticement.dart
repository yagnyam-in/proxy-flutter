import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

class Enticement {
  final String id;
  final String proxyUniverse;
  final String title;
  final String description;
  final int priority;

  Enticement({
    @required this.id,
    @required this.proxyUniverse,
    @required this.title,
    @required this.description,
    @required this.priority,
  });

  static const String ADD_BUNQ_ACCOUNT = "add-bunq-account";
  static const String ADD_RECEIVING_ACCOUNT = "add-receiving-account";
  static const String ADD_TEST_RECEIVING_ACCOUNTS = "add-test-receiving-accounts";

}
