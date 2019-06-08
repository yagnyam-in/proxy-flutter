import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/deposit_service.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/banking/payment_authorization_service.dart';
import 'package:proxy_flutter/banking/withdrawal_service.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:quiver/strings.dart';
import 'package:url_launcher/url_launcher.dart';

class EventActions {
  final DepositService depositService;
  final WithdrawalService withdrawalService;
  final PaymentAuthorizationService paymentService;

  EventActions({
    @required this.depositService,
    @required this.withdrawalService,
    @required this.paymentService,
  });

  List<EventAction> getPossibleActions(
      EventEntity event, ProxyLocalizations localizations) {
    switch (event?.eventType) {
      case EventType.Deposit:
        return possibleActionsForDeposit(event as DepositEvent, localizations);
      case EventType.Withdraw:
        return possibleActionsForWithdrawal(
            event as WithdrawalEvent, localizations);
      default:
        print("Not handled event $event");
        return [];
    }
  }

  Future<void> _launchUrl(String url) async {
    if (isNotEmpty(url) && await canLaunch(url)) {
      await launch(url);
    }
  }

  List<EventAction> possibleActionsForDeposit(
    DepositEvent deposit,
    ProxyLocalizations localizations,
  ) {
    List<EventAction> actions = [];
    if (deposit.isDepositPossible()) {
      actions.add(
        EventAction(
            title: localizations.deposit,
            icon: Icons.file_download,
            action: () => _launchUrl(deposit.depositLink)),
      );
    }
    if (deposit.isCancellable()) {
      actions.add(
        EventAction(
          title: localizations.cancel,
          icon: Icons.close,
          action: () => depositService.cancelDeposit(
                depositId: deposit.depositId,
                proxyUniverse: deposit.proxyUniverse,
              ),
        ),
      );
    }
    return actions;
  }

  List<EventAction> possibleActionsForWithdrawal(
    WithdrawalEvent withdrawal,
    ProxyLocalizations localizations,
  ) {
    List<EventAction> actions = [];
    if (withdrawal.isCancellable()) {
      actions.add(
        EventAction(
          title: localizations.cancel,
          icon: Icons.close,
          action: () {},
        ),
      );
    }
    return actions;
  }
}
