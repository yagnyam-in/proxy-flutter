import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';
import 'package:quiver/strings.dart';
import 'package:url_launcher/url_launcher.dart';

import 'deposit_request_input_dialog.dart';
import 'model/proxy_account_entity.dart';

mixin DepositHelper {
  AppConfiguration get appConfiguration;

  Future<ProxyAccountEntity> fetchOrCreateAccount(ProxyLocalizations localizations, String currency);

  void showToast(String message);

  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  });

  Future<void> createAccountAndDeposit(BuildContext context) async {
    DepositRequestInput depositInput = await acceptDepositRequestInput(context);
    if (depositInput != null) {
      await _updatePreferences(depositInput);
      String depositLink = await invoke(
        () => _createDepositLink(context, depositInput),
        name: 'Create Account & Deposit',
      );
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  Future<void> depositToAccount(
    BuildContext context,
    ProxyAccountEntity proxyAccount,
  ) async {
    DepositRequestInput depositInput = await acceptDepositRequestInput(context, proxyAccount);
    if (depositInput != null) {
      await _updatePreferences(depositInput);
      String depositLink = await invoke(
        () => BankingServiceFactory.depositService(appConfiguration).depositLink(proxyAccount, depositInput),
        name: "Deposit",
      );
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  Future<DepositRequestInput> acceptDepositRequestInput(BuildContext context, [ProxyAccountEntity proxyAccount]) {
    DepositRequestInput depositRequestInput = proxyAccount == null
        ? DepositRequestInput.fromCustomer(appConfiguration)
        : DepositRequestInput.forAccount(appConfiguration, proxyAccount);
    return Navigator.of(context).push(MaterialPageRoute<DepositRequestInput>(
      builder: (context) => DepositRequestInputDialog(
        appConfiguration,
        depositRequestInput: depositRequestInput,
      ),
      fullscreenDialog: true,
    ));
  }

  Future<String> _createDepositLink(BuildContext context, DepositRequestInput depositInput) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ProxyAccountEntity proxyAccount = await fetchOrCreateAccount(localizations, depositInput.currency);
    return BankingServiceFactory.depositService(appConfiguration).depositLink(proxyAccount, depositInput);
  }

  Future<void> _updatePreferences(DepositRequestInput depositInput) async {
    if (isNotEmpty(depositInput.customerPhone) && isEmpty(appConfiguration.phoneNumber)) {
      print("Updating User Phone Number to ${depositInput.customerPhone}");
      return AccountService.updatePreferences(
        appConfiguration,
        appConfiguration.account,
        phone: depositInput.customerPhone,
      );
    }
  }
}
