

import 'package:flutter/material.dart';
import 'package:promo/config/app_configuration.dart';

import 'accept_payment_page.dart';
import 'db/payment_authorization_store.dart';
import 'db/payment_encashment_store.dart';
import 'model/payment_encashment_entity.dart';
import 'payment_authorization_page.dart';
import 'payment_encashment_page.dart';
import 'services/payment_authorization_service.dart';

mixin PaymentLauncher {
  AppConfiguration get appConfiguration;

  Future<void> launchPayment(BuildContext context, Uri paymentLink) async {
    print("Launching dialog to accept payment $paymentLink");
    final query = paymentLink.queryParameters;
    String payerBankId = query[PaymentAuthorizationService.PAYMENT_AUTHORIZATION_BANK_ID_QUERY_PARAM];
    String paymentAuthorizationId = query[PaymentAuthorizationService.PAYMENT_AUTHORIZATION_ID_QUERY_PARAM];

    final paymentAuthorization = await PaymentAuthorizationStore(appConfiguration).fetch(
      bankId: payerBankId,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentAuthorization != null) {
      print("Launching Payment Authorization Page for $paymentLink");
      await Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (context) => PaymentAuthorizationPage.forPaymentAuthorization(
            appConfiguration,
            paymentAuthorization,
          ),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    PaymentEncashmentEntity paymentEncashment = await PaymentEncashmentStore(appConfiguration).fetch(
      payerBankId: payerBankId,
      paymentAuthorizationId: paymentAuthorizationId,
      payeeBankId: null,
      paymentEncashmentId: null,
    );
    if (paymentEncashment != null) {
      print("Launching Payment Encashment Page for for $paymentLink");
      _launchPaymentEncashment(context, paymentEncashment);
      return;
    }
    print("Launching Payment Accept Page for $paymentLink");
    paymentEncashment = await Navigator.push(
      context,
      new MaterialPageRoute<PaymentEncashmentEntity>(
        builder: (context) => AcceptPaymentPage(
          appConfiguration,
          bankId: payerBankId,
          paymentAuthorizationId: paymentAuthorizationId,
          paymentLink: paymentLink.toString(),
        ),
        fullscreenDialog: true,
      ),
    );
    if (paymentEncashment != null) {
      print("Launching Payment Encashment $paymentEncashment as payment is now accepted");
      _launchPaymentEncashment(context, paymentEncashment);
      return;
    }
  }

  Future<void> _launchPaymentEncashment(BuildContext context, PaymentEncashmentEntity paymentEncashment) async {
    await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => PaymentEncashmentPage.forPaymentEncashment(
          appConfiguration,
          paymentEncashment,
        ),
        fullscreenDialog: true,
      ),
    );
  }

}
