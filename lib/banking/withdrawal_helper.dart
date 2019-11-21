import 'package:flutter/material.dart';
import 'package:promo/banking/services/banking_service_factory.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/widgets/basic_types.dart';

import 'model/proxy_account_entity.dart';
import 'model/receiving_account_entity.dart';
import 'receiving_accounts_page.dart';

mixin WithdrawalHelper {
  AppConfiguration get appConfiguration;

  void showToast(String message);

  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  });

  Future<void> withdrawFromAccount(
    BuildContext context,
    ProxyAccountEntity proxyAccount,
  ) async {
    print("_withdraw from $proxyAccount");
    ReceivingAccountEntity receivingAccountEntity = await _chooseReceivingAccountDialog(context, proxyAccount);
    if (receivingAccountEntity != null) {
      print("Actual Withdraw");
      await invoke(
        () => BankingServiceFactory.withdrawalService(appConfiguration).withdraw(proxyAccount, receivingAccountEntity),
        name: "Withdrawal",
        onError: () => showToast(ProxyLocalizations.of(context).somethingWentWrong),
      );
    } else {
      print("Ignoring withdraw");
    }
  }

  Future<ReceivingAccountEntity> _chooseReceivingAccountDialog(
    BuildContext context,
    ProxyAccountEntity proxyAccount,
  ) {
    return Navigator.push(
      context,
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountsPage.choose(
          appConfiguration,
          currency: proxyAccount.balance.currency,
        ),
      ),
    );
  }
}
