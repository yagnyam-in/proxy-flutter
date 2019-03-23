import 'package:flutter/material.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';

typedef EnticementEntity EnticementFactoryMethod(ProxyLocalizations localizations);

class EnticementFactory {
  static const START = "start";
  static const LOAD_MONEY = "loadMoney";
  static const SETUP_BUNQ_ACCOUNT = "setupBunqAccount";

  static final List<MapEntry<String, EnticementFactoryMethod>> factoryMethods = [
    MapEntry(START, start),
    MapEntry(LOAD_MONEY, loadMoney),
    MapEntry(SETUP_BUNQ_ACCOUNT, setupBunqAccount),
  ];

  EnticementFactory();

  factory EnticementFactory.instance() {
    return EnticementFactory();
  }

  Future<EnticementEntity> getEnticement(BuildContext context) async {
    List<EnticementEntity> enticements = await getEnticements(context, 1);
    return enticements.isNotEmpty ? enticements[0] : null;
  }

  Future<List<EnticementEntity>> getEnticements(BuildContext context, [int limit = 1]) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    Set<String> dismissed = await EnticementRepo.instance(DB.instance()).dismissedEnticements();
    List<EnticementEntity> result = factoryMethods
        .where((e) => !dismissed.contains(e.key))
        .map((e) => e.value(localizations))
        .take(limit)
        .toList();
    print("Returning Enticements $result");
    return result;
  }

  Future<void> dismissEnticement(BuildContext context, EnticementEntity enticement) async {
    await EnticementRepo.instance(DB.instance()).dismissEnticement(enticement.enticementId);
  }

  static EnticementEntity start(ProxyLocalizations localizations) {
    return EnticementEntity(
      enticementId: START,
      title: localizations.startBankingTitle,
      description: localizations.startBankingDescription,
      priority: 10,
    );
  }

  static EnticementEntity loadMoney(ProxyLocalizations localizations) {
    return EnticementEntity(
      enticementId: LOAD_MONEY,
      title: localizations.loadMoneyTitle,
      description: localizations.loadMoneyDescription,
      priority: 20,
    );
  }

  static EnticementEntity setupBunqAccount(ProxyLocalizations localizations) {
    return EnticementEntity(
      enticementId: SETUP_BUNQ_ACCOUNT,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
      priority: 30,
    );
  }

}
