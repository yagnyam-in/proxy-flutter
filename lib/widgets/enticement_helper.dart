import 'package:flutter/material.dart';
import 'package:promo/banking/db/receiving_account_store.dart';
import 'package:promo/banking/db/test_receiving_accounts.dart';
import 'package:promo/banking/model/receiving_account_entity.dart';
import 'package:promo/banking/receiving_account_dialog.dart';
import 'package:promo/banking/widgets/enticement_card.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/contact_entity.dart';
import 'package:promo/model/enticement.dart';
import 'package:promo/modify_contact_page.dart';
import 'package:promo/services/enticement_service.dart';
import 'package:promo/utils/data_validations.dart';
import 'package:promo/widgets/widget_helper.dart';
import 'package:uuid/uuid.dart';

mixin EnticementHelper {
  AppConfiguration get appConfiguration;

  Future<void> createPaymentAuthorization(BuildContext context);

  Future<void> createAccountAndDeposit(BuildContext context);

  Future<void> verifyEmail(BuildContext context, String email);

  Future<void> verifyPhoneNumber(BuildContext context, String phoneNumber);

  Future<ReceivingAccountEntity> createReceivingAccount(BuildContext context) {
    return Navigator.of(context).push(
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountDialog(
          appConfiguration,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void showToast(String message);

  Widget enticementCard(BuildContext context, Enticement enticement, {bool cancellable = true}) {
    return EnticementCard(
      enticement: enticement,
      setup: () => launchEnticement(context, enticement),
      dismiss: () => _dismissEnticement(context, enticement),
      dismissable: cancellable,
    );
  }

  Future<void> _dismissEnticement(BuildContext context, Enticement enticement) async {
    print("Dimissing $enticement");
    await EnticementService(appConfiguration).dismissEnticement(
      enticementId: enticement.id,
      proxyUniverse: appConfiguration.proxyUniverse,
    );
  }

  void launchEnticement(BuildContext context, Enticement enticement) {
    print("Launching $enticement");
    switch (enticement.id) {
      case Enticement.ADD_TEST_RECEIVING_ACCOUNTS:
        _addTestAccounts(context, enticement);
        break;
      case Enticement.MAKE_PAYMENT:
        _makePayment(context, enticement);
        break;
      case Enticement.ADD_RECEIVING_ACCOUNT:
      case Enticement.NO_RECEIVING_ACCOUNTS:
        _addReceivingAccount(context, enticement);
        break;
      case Enticement.ADD_BUNQ_ACCOUNT:
        _addBunqAccount(context, enticement);
        break;
      case Enticement.VERIFY_PHONE:
      case Enticement.NO_PHONE_NUMBER_AUTHORIZATIONS:
        _verifyPhoneNumber(context, enticement);
        break;
      case Enticement.VERIFY_EMAIL:
      case Enticement.NO_EMAIL_AUTHORIZATIONS:
        _verifyEmail(context, enticement);
        break;
      case Enticement.ADD_FUNDS:
      case Enticement.NO_PROXY_ACCOUNTS:
      case Enticement.NO_EVENTS:
        _addFunds(context, enticement);
        break;
      case Enticement.NO_CONTACTS:
        _addContact(context, enticement);
        break;
    }
  }

  void _addTestAccounts(BuildContext context, Enticement enticement) {
    print("Add Test Accounts");
    ReceivingAccountStore store = ReceivingAccountStore(appConfiguration);
    TestReceivingAccounts.allTestAccounts.forEach((a) async => await store.saveAccount(a));
    _dismissEnticement(context, enticement);
  }

  void _makePayment(BuildContext context, Enticement enticement) async {
    print("Make Payment");
    try {
      await createPaymentAuthorization(context);
    } catch (e, s) {
      print("Error creating Payment: $e, $s");
    }
  }

  void _addReceivingAccount(BuildContext context, Enticement enticement) async {
    print("Add Receiving Account");
    try {
      ReceivingAccountEntity account = await createReceivingAccount(context);
      if (account != null) {
        await _dismissEnticement(context, enticement);
      }
    } catch (e) {
      print("Error Creating new Receiving Account: $e");
    }
  }

  void _addBunqAccount(BuildContext context, Enticement enticement) {
    showToast("Not yet ready");
    _dismissEnticement(context, enticement);
  }

  void _addFunds(BuildContext context, Enticement enticement) {
    print("Add Receiving Account");
    try {
      createAccountAndDeposit(context);
    } catch (e) {
      print("Error Adding funds: $e");
    }
  }

  void _verifyPhoneNumber(BuildContext context, Enticement enticement) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String phoneNumber = await acceptPhoneNumberDialog(
      context,
      pageTitle: localizations.authorizePhoneNumber,
      fieldName: localizations.customerPhone,
      fieldInitialValue: '+',
    );
    if (isPhoneNumber(phoneNumber)) {
      _dismissEnticement(context, enticement);
      verifyPhoneNumber(context, phoneNumber);
    } else if (phoneNumber != null) {
      showToast(localizations.invalidPhoneNumber);
    }
  }

  void _verifyEmail(BuildContext context, Enticement enticement) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String email = await acceptEmailDialog(
      context,
      pageTitle: localizations.authorizeEmail,
      fieldName: localizations.customerEmail,
    );
    if (isEmailAddress(email)) {
      _dismissEnticement(context, enticement);
      verifyEmail(context, email);
    } else if (email != null) {
      showToast(localizations.invalidEmailAddress);
    }
  }

  void _addContact(BuildContext context, Enticement enticement) async {
    Uuid uuidFactory = Uuid();
    await Navigator.of(context).push(
      new MaterialPageRoute<ContactEntity>(
        builder: (context) => ModifyContactPage(appConfiguration, ContactEntity(id: uuidFactory.v4())),
        fullscreenDialog: true,
      ),
    );
  }
}
