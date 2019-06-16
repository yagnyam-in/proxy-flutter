import 'package:proxy_flutter/banking/services/banking_service.dart';
import 'package:proxy_flutter/banking/services/deposit_service.dart';
import 'package:proxy_flutter/banking/services/payment_authorization_service.dart';
import 'package:proxy_flutter/banking/services/withdrawal_service.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/service_factory.dart';

import 'event_actions.dart';

class BankingServiceFactory {
  static BankingService bankingService(AppConfiguration appConfiguration) {
    return BankingService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
    );
  }

  static WithdrawalService withdrawalService(AppConfiguration appConfiguration) {
    return WithdrawalService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
    );
  }

  static DepositService depositService(AppConfiguration appConfiguration) {
    return DepositService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
    );
  }

  static PaymentAuthorizationService paymentAuthorizationService(AppConfiguration appConfiguration) {
    return PaymentAuthorizationService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      cryptographyService: ServiceFactory.cryptographyService(),
    );
  }

  static EventActions eventActions(AppConfiguration appConfiguration) {
    return EventActions(
      withdrawalService: withdrawalService(appConfiguration),
      depositService: depositService(appConfiguration),
      paymentService: paymentAuthorizationService(appConfiguration),
    );
  }
}
