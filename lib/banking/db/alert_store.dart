import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/escrow.dart';
import 'package:proxy_messages/payments.dart';

class AlertStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  AlertStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference _alertsRef({
    @required String proxyUniverse,
    @required String fcmToken,
  }) {
    return root
        .collection(FirestoreUtils.PROXY_UNIVERSE_NODE)
        .document(proxyUniverse)
        .collection('fcmToken')
        .document(fcmToken)
        .collection('alerts');
  }

  DocumentReference _ref({
    @required String proxyUniverse,
    @required String eventId,
    @required String fcmToken,
  }) {
    return _alertsRef(proxyUniverse: proxyUniverse, fcmToken: fcmToken).document(eventId);
  }

  static Alert fromJson(Map<dynamic, dynamic> json) {
    print("Constructing Alert of type ${json['eventType']}");
    String alertType = json[SignableAlertMessage.ALERT_TYPE];
    switch (alertType) {
      case AccountUpdatedAlert.ALERT_TYPE:
        return AccountUpdatedAlert.fromJson(json);
      case DepositUpdatedAlert.ALERT_TYPE:
        return DepositUpdatedAlert.fromJson(json);
      case WithdrawalUpdatedAlert.ALERT_TYPE:
        return WithdrawalUpdatedAlert.fromJson(json);
      case PaymentAuthorizationUpdatedAlert.ALERT_TYPE:
        return PaymentAuthorizationUpdatedAlert.fromJson(json);
      case PaymentEncashmentUpdatedAlert.ALERT_TYPE:
        return PaymentEncashmentUpdatedAlert.fromJson(json);
      case EscrowAccountUpdatedAlert.ALERT_TYPE:
        return EscrowAccountUpdatedAlert.fromJson(json);
      default:
        print("Unknown alert type $alertType");
        return null;
    }
  }
}
