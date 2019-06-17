import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:proxy_flutter/localizations.dart';

typedef DynamicTranslation = String Function(ProxyLocalizations localizations);

class Enticement {
  final String id;
  final Set<String> proxyUniverses;
  final DynamicTranslation getTitle;
  final DynamicTranslation getDescription;
  final int priority;

  Enticement({
    @required this.id,
    @required this.proxyUniverses,
    DynamicTranslation titleBuilder,
    DynamicTranslation descriptionBuilder,
    @required this.priority,
  })  : getTitle = titleBuilder,
        getDescription = descriptionBuilder;

  @override
  String toString() {
    return "Enticement(id: $id)";
  }

  static const String MAKE_PAYMENT = "make-payment";
  static const String ADD_BUNQ_ACCOUNT = "add-bunq-account";
  static const String ADD_RECEIVING_ACCOUNT = "add-receiving-account";
  static const String ADD_TEST_RECEIVING_ACCOUNTS = "add-test-receiving-accounts";
}