import 'package:proxy_flutter/banking/banking_service.dart';
import 'package:proxy_flutter/banking/deposit_service.dart';
import 'package:proxy_flutter/banking/payment_authorization_service.dart';
import 'package:proxy_flutter/banking/proxy_accounts_bloc.dart';
import 'package:proxy_flutter/banking/receiving_account_bloc.dart';
import 'package:proxy_flutter/banking/withdrawal_service.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_repo.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/receiving_account_repo.dart';
import 'package:proxy_flutter/services/service_factory.dart';

import 'event_actions.dart';

class BankingServiceFactory {
  static ProxyAccountRepo proxyAccountRepo() {
    return ProxyAccountRepo.instance(DB.instance());
  }

  static ReceivingAccountRepo receivingAccountRepo() {
    return ReceivingAccountRepo.instance(DB.instance());
  }

  static PaymentAuthorizationRepo paymentAuthorizationRepo() {
    return PaymentAuthorizationRepo.instance(DB.instance());
  }

  static BankingService bankingService() {
    return BankingService(
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyAccountsBloc: proxyAccountsBloc(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      enticementBloc: ServiceFactory.enticementBloc(),
    );
  }

  static final ReceivingAccountBloc _receivingAccountBlocInstance = ReceivingAccountBloc(
    receivingAccountRepo: receivingAccountRepo(),
  );

  static ReceivingAccountBloc receivingAccountBloc() => _receivingAccountBlocInstance;

  static final ProxyAccountsBloc _proxyAccountsBlocInstance = ProxyAccountsBloc(
    proxyAccountRepo: proxyAccountRepo(),
  );

  static ProxyAccountsBloc proxyAccountsBloc() => _proxyAccountsBlocInstance;

  static WithdrawalService withdrawalService(AppConfiguration appConfig) {
    return WithdrawalService(
      appConfig: appConfig,
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyAccountsBloc: proxyAccountsBloc(),
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

  static PaymentAuthorizationService paymentAuthorizationService() {
    return PaymentAuthorizationService(
      messageFactory: ServiceFactory.messageFactory(),
      messageSigningService: ServiceFactory.messageSigningService(),
      proxyKeyRepo: ServiceFactory.proxyKeyRepo(),
      paymentAuthorizationRepo: paymentAuthorizationRepo(),
      cryptographyService: ServiceFactory.cryptographyService(),
    );
  }

  static EventActions eventActions(AppConfiguration appConfig) {
    return EventActions(
      withdrawalService: withdrawalService(appConfig),
      depositService: depositService(appConfig),
      paymentService: paymentAuthorizationService(),
    );
  }
}
