import 'package:promo/banking/services/banking_service.dart';
import 'package:promo/banking/services/deposit_service.dart';
import 'package:promo/banking/services/payment_authorization_service.dart';
import 'package:promo/banking/services/payment_encashment_service.dart';
import 'package:promo/banking/services/withdrawal_service.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/services/service_factory.dart';

class BankingServiceFactory {
  static BankingService bankingService(AppConfiguration appConfiguration) {
    return BankingService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(appConfiguration),
      messageSigningService: ServiceFactory.messageSigningService(),
    );
  }

  static WithdrawalService withdrawalService(AppConfiguration appConfiguration) {
    return WithdrawalService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(appConfiguration),
      messageSigningService: ServiceFactory.messageSigningService(),
    );
  }

  static DepositService depositService(AppConfiguration appConfiguration) {
    return DepositService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(appConfiguration),
      messageSigningService: ServiceFactory.messageSigningService(),
    );
  }

  static PaymentAuthorizationService paymentAuthorizationService(AppConfiguration appConfiguration) {
    return PaymentAuthorizationService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(appConfiguration),
      messageSigningService: ServiceFactory.messageSigningService(),
      cryptographyService: ServiceFactory.cryptographyService,
      secretsService: ServiceFactory.secretsService(appConfiguration),
    );
  }

  static PaymentEncashmentService paymentEncashmentService(AppConfiguration appConfiguration) {
    return PaymentEncashmentService(
      appConfiguration,
      messageFactory: ServiceFactory.messageFactory(appConfiguration),
      messageSigningService: ServiceFactory.messageSigningService(),
      cryptographyService: ServiceFactory.cryptographyService,
    );
  }
}
