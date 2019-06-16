import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/store/receiving_account_store.dart';
import 'package:proxy_flutter/banking/store/test_receiving_accounts.dart';
import 'package:proxy_flutter/banking/widgets/enticement_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/services/enticement_service.dart';

mixin EnticementHelper {
  AppConfiguration get appConfiguration;

  void createAccountAndPay(BuildContext context);

  Widget enticementCard(BuildContext context, Enticement enticement) {
    return EnticementCard(
      enticement: enticement,
      setup: () => launchEnticement(context, enticement),
      dismiss: () => dismissEnticement(context, enticement),
    );
  }

  void dismissEnticement(BuildContext context, Enticement enticement) {
    print("Dimissing $enticement");
    EnticementService(appConfiguration).dismissEnticement(
      enticementId: enticement.id,
      proxyUniverse: appConfiguration.proxyUniverse,
    );
  }

  void launchEnticement(BuildContext context, Enticement enticement) {
    print("Launching $enticement");
    switch (enticement.id) {
      case Enticement.ADD_TEST_RECEIVING_ACCOUNTS:
        _addTestAccounts();
        dismissEnticement(context, enticement);
        break;
      case Enticement.MAKE_PAYMENT:
        _makePayment(context);
        dismissEnticement(context, enticement);
        break;
      case Enticement.ADD_RECEIVING_ACCOUNT:
      case Enticement.ADD_BUNQ_ACCOUNT:
    }
  }

  void _addTestAccounts() {
    print("Add Test Accounts");
    ReceivingAccountStore store = ReceivingAccountStore(appConfiguration);
    TestReceivingAccounts.allTestAccounts.forEach((a) async => await store.saveAccount(a));
  }

  void _makePayment(BuildContext context) {
    print("Make Payment");
    createAccountAndPay(context);
  }
}
