import 'package:flutter/material.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_page.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';

import 'model/proxy_account_entity.dart';
import 'payment_authorization_input_dialog.dart';

mixin PaymentAuthorizationHelper {
  AppConfiguration get appConfiguration;

  Future<ProxyAccountEntity> fetchOrCreateAccount(
    ProxyLocalizations localizations,
    ProxyId ownerProxyId,
    String currency,
  );

  void showToast(String message);

  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  });

  Future<PaymentAuthorizationEntity> createPaymentAuthorization(BuildContext context) async {
    PaymentAuthorizationInput paymentInput = await _acceptPaymentInput(context);
    if (paymentInput != null) {
      final paymentAuthorization = await invoke(
        () => _createPaymentAuthorization(context, appConfiguration.masterProxyId, paymentInput),
        name: 'Create Payment Authorization',
        onError: () => showToast(ProxyLocalizations.of(context).somethingWentWrong),
      );
      return paymentAuthorization;
    }
    return null;
  }

  Future<void> launchPaymentAuthorization(BuildContext context, PaymentAuthorizationEntity paymentAuthorization) async {
    if (paymentAuthorization != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<PaymentAuthorizationInput>(
          builder: (context) => PaymentAuthorizationPage.forPaymentAuthorization(
            appConfiguration,
            paymentAuthorization,
          ),
        ),
      );
    }
  }

  Future<PaymentAuthorizationInput> _acceptPaymentInput(BuildContext context, [ProxyAccountEntity proxyAccount]) async {
    PaymentAuthorizationInput paymentAuthorizationInput = PaymentAuthorizationInput(
      currency: proxyAccount?.currency,
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

  Future<PaymentAuthorizationEntity> _createPaymentAuthorization(
    BuildContext context,
    ProxyId ownerProxyId,
    PaymentAuthorizationInput paymentInput,
  ) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final proxyAccount = await fetchOrCreateAccount(localizations, ownerProxyId, paymentInput.currency);
    return BankingServiceFactory.paymentAuthorizationService(appConfiguration)
        .createPaymentAuthorization(localizations, proxyAccount, paymentInput);
  }
}
