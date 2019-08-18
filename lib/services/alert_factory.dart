import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/escrow.dart';
import 'package:proxy_messages/payments.dart';

class AlertFactory {
  final AppConfiguration appConfiguration;

  AlertFactory(this.appConfiguration);

  // TODO: Must be verified. Use MessageFactory instead of factory methods
  Future<SignedMessage<SignableAlertMessage>> createAlert(Map json) async {
    String type = json['type'];
    switch (type) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedAlert.signedMessageFromJson(json);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedAlert.signedMessageFromJson(json);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedAlert.signedMessageFromJson(json);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentAuthorizationUpdatedAlert.signedMessageFromJson(json);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedAlert.signedMessageFromJson(json);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedAlert.signedMessageFromJson(json);
      default:
        print("Unknnown Alert Type $type");
        return null;
    }
  }
}
