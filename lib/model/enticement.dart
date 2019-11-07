import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:promo/localizations.dart';

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
  static const String ADD_FUNDS = "add-funds";
  static const String VERIFY_EMAIL = "verify-email";
  static const String VERIFY_PHONE = "verify-phone";

  static const String NO_EVENTS = "no-events";
  static const String NO_PROXY_ACCOUNTS = "no-proxy-accounts";
  static const String NO_RECEIVING_ACCOUNTS = "no-receiving-accounts";
  static const String NO_PHONE_NUMBER_AUTHORIZATIONS = "no-phone-number-authorizations";
  static const String NO_EMAIL_AUTHORIZATIONS = "no-email-authorizations";
  static const String NO_CONTACTS = "no-contacts";

  static const String ADD_TEST_RECEIVING_ACCOUNTS = "add-test-receiving-accounts";
}
