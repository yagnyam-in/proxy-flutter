import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/db/receiving_account_store.dart';
import 'package:proxy_flutter/banking/db/test_receiving_accounts.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/banking/widgets/enticement_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/services/enticement_service.dart';

mixin EnticementHelper {
  AppConfiguration get appConfiguration;

  Future<Uri> createAccountAndPay(BuildContext context);

  Future<void> createAccountAndDeposit(BuildContext context);

  Future<ReceivingAccountEntity> createReceivingAccount(BuildContext context) {
    return Navigator.of(context).push(
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountDialog(
          appConfiguration,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void showToast(String message);

  Widget enticementCard(BuildContext context, Enticement enticement, {bool cancellable = true}) {
    return EnticementCard(
      enticement: enticement,
      setup: () => launchEnticement(context, enticement),
      dismiss: () => dismissEnticement(context, enticement),
      dismissable: cancellable,
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
        _addTestAccounts(context, enticement);
        break;
      case Enticement.MAKE_PAYMENT:
        _makePayment(context, enticement);
        break;
      case Enticement.ADD_RECEIVING_ACCOUNT:
      case Enticement.NO_RECEIVING_ACCOUNTS:
        _addReceivingAccount(context, enticement);
        break;
      case Enticement.ADD_BUNQ_ACCOUNT:
        _addBunqAccount(context, enticement);
        break;
      case Enticement.ADD_FUNDS:
      case Enticement.NO_PROXY_ACCOUNTS:
      case Enticement.NO_EVENTS:
        _addFunds(context, enticement);
        break;
    }
  }

  void _addTestAccounts(BuildContext context, Enticement enticement) {
    print("Add Test Accounts");
    ReceivingAccountStore store = ReceivingAccountStore(appConfiguration);
    TestReceivingAccounts.allTestAccounts.forEach((a) async => await store.saveAccount(a));
    dismissEnticement(context, enticement);
  }

  void _makePayment(BuildContext context, Enticement enticement) async {
    print("Make Payment");
    try {
      Uri uri = await createAccountAndPay(context);
      if (uri != null) {
        dismissEnticement(context, enticement);
      }
    } catch (e, s) {
      print("Error creating Payment: $e, $s");
    }
  }

  void _addReceivingAccount(BuildContext context, Enticement enticement) async {
    print("Add Receiving Account");
    try {
      ReceivingAccountEntity account = await createReceivingAccount(context);
      if (account != null) {
        dismissEnticement(context, enticement);
      }
    } catch (e) {
      print("Error Creating new Receiving Account: $e");
    }
  }

  void _addBunqAccount(BuildContext context, Enticement enticement) {
    showToast("Not yet ready");
    dismissEnticement(context, enticement);
  }

  void _addFunds(BuildContext context, Enticement enticement) {
    print("Add Receiving Account");
    try {
      createAccountAndDeposit(context);
    } catch (e) {
      print("Error Adding funds: $e");
    }
  }
}
