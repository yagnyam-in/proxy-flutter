import 'package:flutter/material.dart';
import 'package:promo/config/app_configuration.dart';

import 'deposit_page.dart';
import 'model/deposit_event.dart';
import 'model/event_entity.dart';
import 'model/payment_authorization_event.dart';
import 'model/payment_encashment_event.dart';
import 'model/withdrawal_event.dart';
import 'payment_authorization_page.dart';
import 'payment_encashment_page.dart';
import 'withdrawal_page.dart';

mixin EventsHelper {
  AppConfiguration get appConfiguration;

  void launchEvent(BuildContext context, EventEntity event) {
    Widget eventPage = _eventPage(event);
    if (eventPage == null) {
      return;
    }
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => eventPage,
      ),
    );
  }

  Widget _eventPage(EventEntity event) {
    switch (event.eventType) {
      case EventType.Deposit:
        return DepositPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          depositId: (event as DepositEvent).depositId,
        );
      case EventType.Withdrawal:
        return WithdrawalPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          withdrawalId: (event as WithdrawalEvent).withdrawalId,
        );
      case EventType.PaymentAuthorization:
        return PaymentAuthorizationPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          paymentAuthorizationId: (event as PaymentAuthorizationEvent).paymentAuthorizationId,
        );
      case EventType.PaymentEncashment:
        return PaymentEncashmentPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          paymentEncashmentId: (event as PaymentEncashmentEvent).paymentEncashmentId,
          paymentAuthorizationId: (event as PaymentEncashmentEvent).paymentAuthorizationId,
        );
      default:
        return null;
    }
  }
}
