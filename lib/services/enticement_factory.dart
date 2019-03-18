import 'package:flutter/material.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';

typedef EnticementEntity EnticementFactoryMethod(ProxyLocalizations localizations);

class EnticementFactory {
  static const SETUP_BUNQ_ACCOUNT = "setupBunqAccount";
  static const LOAD_MONEY = "loadMoney";
  static final Map<String, EnticementFactoryMethod> factoryMethods = {
    SETUP_BUNQ_ACCOUNT: setupBunqAccount,
    LOAD_MONEY: loadMoney,
  };

  EnticementFactory();

  factory EnticementFactory.instance() {
    return EnticementFactory();
  }

  Future<List<EnticementEntity>> getEnticements(BuildContext context, [int limit = 2]) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    Set<String> dismissed = await EnticementRepo.instance(DB.instance()).dismissedEnticements();
    List<EnticementEntity> result = new List();
    for (MapEntry<String, EnticementFactoryMethod> entry in factoryMethods.entries) {
      if (result.length < limit && !dismissed.contains(entry.key)) {
        result.add(entry.value(localizations));
      }
    }
    return result;
  }

  static EnticementEntity setupBunqAccount(ProxyLocalizations localizations) {
    return EnticementEntity(
      enticementId: SETUP_BUNQ_ACCOUNT,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
      priority: 1,
    );
  }

  static EnticementEntity loadMoney(ProxyLocalizations localizations) {
    return EnticementEntity(
      enticementId: SETUP_BUNQ_ACCOUNT,
      title: localizations.loadMoneyTitle,
      description: localizations.loadMoneyDescription,
      priority: 0,
    );
  }
}
