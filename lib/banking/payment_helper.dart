import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';
import 'package:quiver/strings.dart';
import 'package:share/share.dart';

import 'model/proxy_account_entity.dart';
import 'payment_authorization_input_dialog.dart';

mixin PaymentHelper {
  AppConfiguration get appConfiguration;

  Future<ProxyAccountEntity> fetchOrCreateAccount(ProxyLocalizations localizations, String currency);

  void showToast(String message);

  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  });

  Future<Uri> createAccountAndPay(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    PaymentAuthorizationInput paymentInput = await _acceptPaymentInput(context);
    if (paymentInput != null) {
      Uri paymentLink = await invoke(
        () => _createPaymentLink(context, paymentInput),
        name: 'Create Account & Pay',
      );
      if (paymentLink != null) {
        String customerName = appConfiguration.displayName;
        var from = isNotEmpty(customerName) ? ' - $customerName' : '';
        var message = localizations.acceptPayment(paymentLink.toString() + from);
        await Share.share(message);
      }
      return paymentLink;
    }
    return null;
  }

  Future<PaymentAuthorizationInput> _acceptPaymentInput(BuildContext context, [ProxyAccountEntity proxyAccount]) async {
    PaymentAuthorizationInput paymentAuthorizationInput = PaymentAuthorizationInput(
      currency: proxyAccount?.currency,
      payees: [
        PaymentAuthorizationPayeeInput(
          secret: RandomUtils.randomSecret(),
        ),
      ],
    );
    PaymentAuthorizationInput result = await Navigator.of(context).push(
      MaterialPageRoute<PaymentAuthorizationInput>(
        builder: (context) => PaymentAuthorizationInputDialog(
          appConfiguration,
          paymentAuthorizationInput: paymentAuthorizationInput,
        ),
        fullscreenDialog: true,
      ),
    );
    return result;
  }

  Future<Uri> _createPaymentLink(
    BuildContext context,
    PaymentAuthorizationInput paymentInput,
  ) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    ProxyAccountEntity proxyAccount = await fetchOrCreateAccount(localizations, paymentInput.currency);
    return BankingServiceFactory.paymentAuthorizationService(appConfiguration).createPaymentAuthorization(
      localizations,
      proxyAccount,
      paymentInput,
    );
  }
}
