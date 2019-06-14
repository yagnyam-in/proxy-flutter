import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement.dart';

// Priority 0 means highest
class EnticementFactory {

  List<Enticement> getEnticements(ProxyLocalizations localizations, String proxyUniverse) {
    List<Enticement> enticements = [
      addBunqAccount(localizations),
      addReceivingAccount(localizations),
      addTestReceivingAccounts(localizations),
    ];
    return enticements.takeWhile((e) => e.proxyUniverse == proxyUniverse).toList();
  }

  static Enticement addBunqAccount(ProxyLocalizations localizations) {
    return Enticement(
      proxyUniverse: ProxyUniverse.PRODUCTION,
      id: Enticement.ADD_BUNQ_ACCOUNT,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
      priority: 300,
    );
  }

  static Enticement addReceivingAccount(ProxyLocalizations localizations) {
    return Enticement(
      proxyUniverse: ProxyUniverse.PRODUCTION,
      id: Enticement.ADD_RECEIVING_ACCOUNT,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
      priority: 200,
    );
  }

  static Enticement addTestReceivingAccounts(ProxyLocalizations localizations) {
    return Enticement(
      proxyUniverse: ProxyUniverse.TEST,
      id: Enticement.ADD_TEST_RECEIVING_ACCOUNTS,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
      priority: 100,
    );
  }
}
