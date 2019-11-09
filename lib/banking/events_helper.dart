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
          depositInternalId: (event as DepositEvent).depositInternalId,
        );
      case EventType.Withdrawal:
        return WithdrawalPage(
          appConfiguration,
          withdrawalInternalId: (event as WithdrawalEvent).withdrawalInternalId,
        );
      case EventType.PaymentAuthorization:
        return PaymentAuthorizationPage(
          appConfiguration,
          paymentAuthorizationInternalId: (event as PaymentAuthorizationEvent).paymentAuthorizationInternalId,
        );
      case EventType.PaymentEncashment:
        return PaymentEncashmentPage(
          appConfiguration,
          paymentEncashmentInternalId: (event as PaymentEncashmentEvent).paymentEncashmentInternalId,
        );
      default:
        return null;
    }
  }
}
