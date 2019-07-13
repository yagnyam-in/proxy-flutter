import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';

import 'db/proxy_account_store.dart';
import 'model/proxy_account_entity.dart';

mixin AccountHelper {
  AppConfiguration get appConfiguration;

  void showToast(String message);

  Future<ProxyAccountEntity> fetchOrCreateAccount(ProxyLocalizations localizations, String currency) async {
    return BankingServiceFactory.bankingService(appConfiguration).fetchOrCreateProxyWallet(
      ownerProxyId: appConfiguration.masterProxyId,
      proxyUniverse: appConfiguration.proxyUniverse,
      currency: currency,
    );
  }

  Future<void> refreshAccount(BuildContext context, ProxyAccountEntity proxyAccount) {
    print("refresh $proxyAccount");
    return BankingServiceFactory.bankingService(appConfiguration).refreshAccount(proxyAccount.accountId);
  }

  Future<void> archiveAccount(BuildContext context, ProxyAccountEntity proxyAccount) {
    print("archive $proxyAccount");
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (proxyAccount.balance.value != 0) {
      showToast(localizations.canNotDeleteActiveAccount);
      return Future.value(null);
    }
    return ProxyAccountStore(appConfiguration).deleteAccount(proxyAccount);
  }
}
