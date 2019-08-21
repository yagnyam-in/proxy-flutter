import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/escrow.dart';
import 'package:proxy_messages/payments.dart';

class AlertFactory {
  final AppConfiguration appConfiguration;

  AlertFactory(this.appConfiguration);

  // TODO: Must be verified. Use MessageFactory instead of factory methods
  Future<SignedMessage<SignableAlertMessage>> createAlert(Map alertJson) async {
    String alertType = alertJson['type'];
    switch (alertType) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedAlert.signedMessageFromJson(alertJson);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedAlert.signedMessageFromJson(alertJson);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedAlert.signedMessageFromJson(alertJson);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentAuthorizationUpdatedAlert.signedMessageFromJson(alertJson);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedAlert.signedMessageFromJson(alertJson);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedAlert.signedMessageFromJson(alertJson);
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
