import 'package:proxy_flutter/banking/banking_service.dart';
import 'package:proxy_flutter/banking/deposit_service.dart';
import 'package:proxy_flutter/banking/payment_authorization_service.dart';
import 'package:proxy_flutter/banking/withdrawal_service.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/service_factory.dart';

import 'event_actions.dart';

class BankingServiceFactory {
  static BankingService bankingService() {
    return BankingService(
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      enticementBloc: ServiceFactory.enticementBloc(),
    );
  }

  static WithdrawalService withdrawalService(AppConfiguration appConfig) {
    return WithdrawalService(
      appConfig: appConfig,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
    );
  }

  static DepositService depositService(AppConfiguration appConfig) {
    return DepositService(
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      appConfig: appConfig,
    );
  }

  static PaymentAuthorizationService paymentAuthorizationService(AppConfiguration appConfig) {
    return PaymentAuthorizationService(
      appConfig: appConfig,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      cryptographyService: ServiceFactory.cryptographyService(),
    );
  }

  static EventActions eventActions(AppConfiguration appConfig) {
    return EventActions(
      withdrawalService: withdrawalService(appConfig),
      depositService: depositService(appConfig),
      paymentService: paymentAuthorizationService(appConfig),
    );
  }
}
