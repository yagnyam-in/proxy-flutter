import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/escrow.dart';
import 'package:proxy_messages/payments.dart';

class AlertFactory {
  static Alert createAlert(Map<String, dynamic> alertMap) {
    String type = alertMap['alertType'];
    switch (type) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedAlert.fromJson(alertMap);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedAlert.fromJson(alertMap);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedAlert.fromJson(alertMap);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentAuthorizationUpdatedAlert.fromJson(alertMap);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedAlert.fromJson(alertMap);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedAlert.fromJson(alertMap);
      default:
        print("Unknnown Alert Type $type");
        return null;
    }
  }
}
