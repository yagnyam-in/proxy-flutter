import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/escrow.dart';
import 'package:proxy_messages/payments.dart';

class AlertFactory {
  SignableAlertMessage createAlert(String alertType, Map alertJson) {
    switch (alertType) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedAlert.fromJson(alertJson);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedAlert.fromJson(alertJson);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedAlert.fromJson(alertJson);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentAuthorizationUpdatedAlert.fromJson(alertJson);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedAlert.fromJson(alertJson);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedAlert.fromJson(alertJson);
      default:
        print("Unknnown Alert Type $alertType");
        return null;
    }
  }

  LiteAlert createLiteAlert(Map alertJson) {
    String alertType = alertJson[SignableAlertMessage.FIELD_ALERT_TYPE];
    switch (alertType) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedLiteAlert.fromJson(alertJson);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedLiteAlert.fromJson(alertJson);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedLiteAlert.fromJson(alertJson);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedLiteAlert.fromJson(alertJson);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedLiteAlert.fromJson(alertJson);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedLiteAlert.fromJson(alertJson);
      default:
        print("Unknnown Alert Type $alertType");
        return null;
    }
  }
}
