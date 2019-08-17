import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/alert_store.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';

class AlertService {
  final AppConfiguration appConfiguration;
  final AlertStore _alertStore;

  AlertService(this.appConfiguration) : _alertStore = AlertStore(appConfiguration);

  Future<void> processPendingAlerts() async {
    print("processPendingAlerts");

    // Retry but limited times
    for (int i = 0; i < 4; i++) {
      final pendingAlerts = await _alertStore.fetchPendingAlerts();
      pendingAlerts.forEach((alertRef, alert) {
        try {
          _processAlert(alert);
        } catch (e) {
          print("Error Processing Alert: $e");
        } finally {
          _alertStore.deleteAlert(alertRef);
        }
      });
      if (pendingAlerts.isEmpty) {
        break;
      }
    }
  }

  Future<void> _processAlert(Alert alert) async {
    if (alert is AccountUpdatedAlert) {
      return BankingServiceFactory.bankingService(appConfiguration).refreshAccount(alert.proxyAccountId);
    } else if (alert is DepositUpdatedAlert) {
      BankingServiceFactory.depositService(appConfiguration).processDepositUpdate(alert);
    } else if (alert is WithdrawalUpdatedAlert) {
      BankingServiceFactory.withdrawalService(appConfiguration).processWithdrawalUpdate(alert);
    } else if (alert is PaymentAuthorizationUpdatedAlert) {
      BankingServiceFactory.paymentAuthorizationService(appConfiguration).processPaymentAuthorizationUpdate(alert);
    } else if (alert is PaymentEncashmentUpdatedAlert) {
      BankingServiceFactory.paymentEncashmentService(appConfiguration).processPaymentEncashmentUpdate(alert);
    } else {
      print("$alert is not handled");
    }
  }
}
