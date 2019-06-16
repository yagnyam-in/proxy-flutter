import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement.dart';

// Priority 0 means highest
class EnticementFactory {
  List<Enticement> getEnticements(String proxyUniverse) {
    print("Get Enticements for proxyUniverse: $proxyUniverse");
    List<Enticement> enticements = [
      addTestReceivingAccounts,
      makePayment,
      addReceivingAccount,
      addBunqAccount,
    ];
    enticements.sort((e1, e2) => Comparable.compare(e1.priority, e2.priority));
    print("Enticements for proxyUniverse: $proxyUniverse => $enticements");
    return enticements.takeWhile((e) => e.proxyUniverses.contains(proxyUniverse)).toList();
  }


  static Enticement get addTestReceivingAccounts {
    return Enticement(
      proxyUniverses: {ProxyUniverse.TEST},
      id: Enticement.ADD_TEST_RECEIVING_ACCOUNTS,
      titleBuilder: (ProxyLocalizations localizations) => localizations.addTestReceivingAccountsTitle,
      descriptionBuilder: (ProxyLocalizations localizations) => localizations.addTestReceivingAccountsDescription,
      priority: 100,
    );
  }


  static Enticement get makePayment {
    return Enticement(
      proxyUniverses: {ProxyUniverse.PRODUCTION, ProxyUniverse.TEST},
      id: Enticement.MAKE_PAYMENT,
      titleBuilder: (ProxyLocalizations localizations) => localizations.makePaymentTitle,
      descriptionBuilder: (ProxyLocalizations localizations) => localizations.makePaymentDescription,
      priority: 200,
    );
  }


  static Enticement get addReceivingAccount {
    return Enticement(
      proxyUniverses: {ProxyUniverse.PRODUCTION, ProxyUniverse.TEST},
      id: Enticement.ADD_RECEIVING_ACCOUNT,
      titleBuilder: (localizations) => localizations.addReceivingAccountTitle,
      descriptionBuilder: (localizations) => localizations.addReceivingAccountDescription,
      priority: 300,
    );
  }


  static Enticement get addBunqAccount {
    return Enticement(
      proxyUniverses: {ProxyUniverse.PRODUCTION, ProxyUniverse.TEST},
      id: Enticement.ADD_BUNQ_ACCOUNT,
      titleBuilder: (ProxyLocalizations localizations) => localizations.addBunqAccountTitle,
      descriptionBuilder: (ProxyLocalizations localizations) => localizations.addBunqAccountDescription,
      priority: 400,
    );
  }

}
