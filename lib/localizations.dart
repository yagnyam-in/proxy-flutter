import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_all.dart';

class ProxyLocalizations {
  static Future<ProxyLocalizations> load(Locale locale) {
    final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return ProxyLocalizations();
    });
  }

  static ProxyLocalizations of(BuildContext context) {
    return Localizations.of<ProxyLocalizations>(context, ProxyLocalizations);
  }

  String get title {
    return Intl.message(
      'Proxy',
      name: 'title',
      desc: 'Title for the Proxy application',
    );
  }

  String get getStarted {
    return Intl.message(
      'Start',
      name: 'getStarted',
      desc: 'Title for starting with Proxy application',
    );
  }

  String get startupError {
    return Intl.message(
      'Error Starting Up',
      name: 'startupError',
      desc: 'Error while starting up Proxy application',
    );
  }

  String get setupMasterProxyTitle {
    return Intl.message(
      'Setup Master Key',
      name: 'setupMasterProxyTitle',
      desc: 'Setup Master Proxy Page Title',
    );
  }

  String get masterProxyDescription {
    return Intl.message(
      'Master Key is never used directly for any transaction, it is used to authorize temporary keys.',
      name: 'masterProxyDescription',
      desc: 'Description of Master Proxy/Key',
    );
  }

  String get revocationPassPhraseDescription {
    return Intl.message(
      'Revocation Pass Phrase is useful in case you want to de-activate a Key(s).',
      name: 'revocationPassPhraseDescription',
      desc: 'Description of Revocation Pass Phrase',
    );
  }

  String get proxyId {
    return Intl.message(
      'Proxy Id',
      name: 'proxyId',
      desc: 'Proxy Id',
    );
  }

  String get proxyIdHint {
    return Intl.message(
      'Alpha numerics and hyphens',
      name: 'proxyIdHint',
      desc: 'Proxy Id hint like characters allowed',
    );
  }

  String get invalidProxyId {
    return Intl.message(
      'Should be of length 8-36, alpha numerics and hyphens are only allowed',
      name: 'invalidProxyId',
      desc: 'Proxy Id entered by user is invalid',
    );
  }

  String get revocationPassPhrase {
    return Intl.message(
      'Pass Phrase',
      name: 'revocationPassPhrase',
      desc: 'Pass Phrase to use for revoking the Proxy Id',
    );
  }

  String get revocationPassPhraseHint {
    return Intl.message(
      'Alpha Numerics, spaces and Special Symbols',
      name: 'revocationPassPhraseHint',
      desc: 'Pass Phrase hint like characters allowed',
    );
  }

  String get invalidRevocationPassPhrase {
    return Intl.message(
      'Should be of length 8-64',
      name: 'invalidRevocationPassPhrase',
      desc: 'Revocation Pass Phrase entered by user is invalid',
    );
  }

  String get termsAndConditionsPageTitle {
    return Intl.message(
      'Terms & Conditions',
      name: 'termsAndConditionsPageTitle',
      desc: 'Page title for accepting terms & conditions',
    );
  }

  String get readTermsAndConditions {
    return Intl.message(
      'Also accept Terms & Conditions mentioned at ',
      name: 'readTermsAndConditions',
      desc: 'I agree terms & conditions',
    );
  }

  String get termsAndConditionsURL {
    return Intl.message(
      'https://www.pxy.yagnyam.in/tc',
      name: 'termsAndConditionsURL',
      desc: 'Terms & Conditions URL',
    );
  }

  String get agreeTermsAndConditions {
    return Intl.message(
      'I agree terms & conditions',
      name: 'agreeTermsAndConditions',
      desc: 'I agree terms & conditions',
    );
  }

  String get setupProxyButtonLabel {
    return Intl.message(
      'Setup',
      name: 'setupProxyButtonLabel',
      desc: 'Setup Proxy Button Label',
    );
  }

  String get start {
    return Intl.message(
      'Start',
      name: 'start',
      desc: 'label for Start',
    );
  }

  String fieldIsMandatory(String fieldName) {
    return Intl.message(
      '$fieldName is mandatory',
      name: 'fieldIsMandatory',
      args: [fieldName],
      desc: 'Pass Phrase to use for revoking the Proxy Id',
      examples: {
        'fieldName': 'Proxy Id',
      },
    );
  }

  String get failedProxyCreation {
    return Intl.message(
      'Id might be taken. Try different Id',
      name: 'failedProxyCreation',
      desc: 'Failed to Create Proxy',
    );
  }

  String get bankingTitle {
    return Intl.message(
      'Banking',
      name: 'bankingTitle',
      desc: 'Banking',
    );
  }

  String get deposit {
    return Intl.message(
      'Deposit',
      name: 'deposit',
      desc: 'Load Money',
    );
  }

  String get payment {
    return Intl.message(
      'Pay',
      name: 'payment',
      desc: 'Make Payment',
    );
  }

  String get withdraw {
    return Intl.message(
      'Withdraw',
      name: 'withdraw',
      desc: 'Withdraw from Wallet',
    );
  }

  String get archive {
    return Intl.message(
      'Archive',
      name: 'archive',
      desc: 'Archive Wallet',
    );
  }

  String get startBankingTitle {
    return Intl.message(
      'Start Banking',
      name: 'startBankingTitle',
      desc: 'Start Banking',
    );
  }

  String get startBankingDescription {
    return Intl.message(
      'Start making payments anonymously',
      name: 'startBankingDescription',
      desc: 'Start Banking description',
    );
  }

  String get addBunqAccountTitle {
    return Intl.message(
      'Add Bunq account',
      name: 'setupBunqAccountTitle',
      desc: 'Add Bunq account',
    );
  }

  String get addBunqAccountDescription {
    return Intl.message(
      'By Adding your Bunq account, you can directly start using it anonymously',
      name: 'setupBunqAccountDescription',
      desc: 'By Adding your Bunq account, you can directly start using it anonymously',
    );
  }

  String get loadMoneyTitle {
    return Intl.message(
      'Load Money',
      name: 'loadMoneyTitle',
      desc: 'Load Money',
    );
  }

  String get loadMoneyDescription {
    return Intl.message(
      'By already loading Money, you can make Payments faster',
      name: 'loadMoneyDescription',
      desc: 'By already loading Money, you can make Payments faster',
    );
  }

  String get errorLoadingAccounts {
    return Intl.message(
      'Failed to fetch existing accounts',
      name: 'errorLoadingAccounts',
      desc: 'Failed to fetch existing accounts',
    );
  }

  String creatingAnonymousAccount(String currency) {
    return Intl.message(
      'Creating Anonymous $currency Account',
      name: 'creatingAccount',
      args: [currency],
      desc: 'Creating Anonymous Account for given Currency',
      examples: {
        'currency': 'EUR',
      },
    );
  }

  String get canNotDeleteActiveAccount {
    return Intl.message(
      'Account is no empty to delete',
      name: 'canNotDeleteActiveAccount',
      desc: 'Account is not empty to delete',
    );
  }

  String get depositRequestInputTitle {
    return Intl.message(
      'Deposit Details',
      name: 'depositRequestInputTitle',
      desc: 'Dialog title to deposit',
    );
  }

  String get paymentAuthorizationInputTitle {
    return Intl.message(
      'Payment Details',
      name: 'paymentAuthorizationInputTitle',
      desc: 'Dialog title for payment',
    );
  }

  String get invalidAmount {
    return Intl.message(
      'Invalid Amount',
      name: 'invalidAmount',
      desc: 'Invalid Amount',
    );
  }

  String get currency {
    return Intl.message(
      'Currency',
      name: 'currency',
      desc: 'Currency',
    );
  }

  String get currencyHint {
    return Intl.message(
      'Choose Currency',
      name: 'currencyHint',
      desc: 'Hint for Currency',
    );
  }

  String get amount {
    return Intl.message(
      'Amount',
      name: 'amount',
      desc: 'Amount',
    );
  }

  String get amountHint {
    return Intl.message(
      'Amount',
      name: 'amountHint',
      desc: 'Only smaller denominations are allowed',
    );
  }

  String get okButtonLabel {
    return Intl.message(
      'OK',
      name: 'okButtonLabel',
      desc: 'OK',
    );
  }

  String get refreshButtonHint {
    return Intl.message(
      'Refresh',
      name: 'refreshButtonHint',
      desc: 'Refresh Button Hint',
    );
  }

  String get receivingAccountsButtonHint {
    return Intl.message(
      'Receiving Accounts',
      name: 'receivingAccountsButtonHint',
      desc: 'Receiving Accounts Button Hint',
    );
  }

  String get manageReceivingAccountsPageTitle {
    return Intl.message(
      'Receiving Accounts',
      name: 'manageReceivingAccountsPageTitle',
      desc: 'Receiving Accounts Page Hint',
    );
  }

  String get chooseReceivingAccountsPageTitle {
    return Intl.message(
      'Choose Account',
      name: 'chooseReceivingAccountsPageTitle',
      desc: 'Receiving Accounts Page Hint',
    );
  }

  String get newReceivingAccountsButtonHint {
    return Intl.message(
      'New Account',
      name: 'newReceivingAccountsButtonHint',
      desc: 'New Receiving Account Button Hint',
    );
  }

  String get manageContactsPageTitle {
    return Intl.message(
      'Contacts',
      name: 'manageContactsPageTitle',
      desc: 'Contacts Page Title',
    );
  }

  String get chooseContactsPageTitle {
    return Intl.message(
      'Choose Contact',
      name: 'chooseContactsPageTitle',
      desc: 'Choose Contact Page Title',
    );
  }

  String get thisField {
    return Intl.message(
      'This field',
      name: 'thisField',
      desc: 'This field - to show in errors',
    );
  }

  String get bank {
    return Intl.message(
      'Bank',
      name: 'bank',
      desc: 'Bank field name',
    );
  }

  String get accountNumber {
    return Intl.message(
      'Account Number',
      name: 'accountNumber',
      desc: 'Account Number field name',
    );
  }

  String get accountHolder {
    return Intl.message(
      'Account Holder',
      name: 'accountHolder',
      desc: 'Account Holder field name',
    );
  }

  String get accountName {
    return Intl.message(
      'Account Name',
      name: 'accountName',
      desc: 'Account Name field name',
    );
  }

  String get ifscCode {
    return Intl.message(
      'IFSC Code',
      name: 'ifscCode',
      desc: 'IFSC code field name',
    );
  }

  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: 'Edit',
    );
  }

  String get proxyUniverse {
    return Intl.message(
      'Proxy Universe',
      name: 'proxyUniverse',
      desc: 'Proxy Universe',
    );
  }

  String get chooseReceivingAccount {
    return Intl.message(
      'Choose Account',
      name: 'chooseReceivingAccount',
      desc: 'Choose Receiving Account',
    );
  }

  String get newReceivingAccountTitle {
    return Intl.message(
      'New Account',
      name: 'newReceivingAccountTitle',
      desc: 'New Receiving Account',
    );
  }

  String get modifyReceivingAccountTitle {
    return Intl.message(
      'Modify',
      name: 'modifyReceivingAccountTitle',
      desc: 'Modify Receiving Account',
    );
  }

  String get customerName {
    return Intl.message(
      'Name',
      name: 'customerName',
      desc: 'Customer Name',
    );
  }

  String get customerPhone {
    return Intl.message(
      'Phone',
      name: 'customerPhone',
      desc: 'Customer Phone',
    );
  }

  String get customerEmail {
    return Intl.message(
      'Email',
      name: 'customerEmail',
      desc: 'Customer Email',
    );
  }

  String get customerAddress {
    return Intl.message(
      'Address',
      name: 'customerAddress',
      desc: 'Customer Address',
    );
  }

  String get notEligibleForArchiving {
    return Intl.message(
      'Not eligible for Archiving',
      name: 'notEligibleForArchiving',
      desc: 'Not eligible for Archiving',
    );
  }

  String get withdrawalNotYetComplete {
    return Intl.message(
      'Not Complete',
      name: 'withdrawalNotYetComplete',
      desc: 'Not Complete',
    );
  }

  String get eventsPageTitle {
    return Intl.message(
      'Events',
      name: 'eventsPageTitle',
      desc: 'Events',
    );
  }

  String get paymentEventTitle {
    return Intl.message(
      'Payment',
      name: 'paymentEventTitle',
      desc: 'Payment event title',
    );
  }

  String get fxEventTitle {
    return Intl.message(
      'Forex',
      name: 'fxEventTitle',
      desc: 'Forex event title',
    );
  }

  String get unknownEventTitle {
    return Intl.message(
      'Event',
      name: 'unknownEventTitle',
      desc: 'Unknown event title',
    );
  }

  String get withdrawalEventTitle {
    return Intl.message(
      'Withdrawal',
      name: 'withdrawalEventTitle',
      desc: 'withdrawal event title',
    );
  }

  String withdrawalEventSubTitle(String destinationAccount) {
    return Intl.message(
      'Account: $destinationAccount',
      name: 'withdrawalEventSubTitle',
      args: [destinationAccount],
      desc: 'Withdrawing to Account',
      examples: {
        'destinationAccount': 'NL11INGB040037899',
      },
    );
  }

  String get depositEventTitle {
    return Intl.message(
      'Deposit',
      name: 'depositEventTitle',
      desc: 'deposit event title',
    );
  }

  String depositEventSubTitle(String destinationAccount) {
    return Intl.message(
      'Account: $destinationAccount',
      name: 'depositEventSubTitle',
      args: [destinationAccount],
      desc: 'Depositing to Account',
      examples: {
        'destinationAccount': 'abcd-defghij',
      },
    );
  }

  String get registered => Intl.message(
        'Registered',
        name: 'registered',
        desc: 'Registered',
      );

  String get rejected => Intl.message(
        'Rejected',
        name: 'rejected',
        desc: 'Rejected',
      );

  String get inTransit => Intl.message(
        'In Transit',
        name: 'inTransit',
        desc: 'In Transit',
      );

  String get completed => Intl.message(
        'Completed',
        name: 'completed',
        desc: 'Completed',
      );

  String get failedInTransit => Intl.message(
        'Failed',
        name: 'failedInTransit',
        desc: 'Failed',
      );

  String get failedCompleted => Intl.message(
        'Failed',
        name: 'failedCompleted',
        desc: 'Failed',
      );

  String get waitingForFunds => Intl.message(
        'Waiting for Funds',
        name: 'waitingForFunds',
        desc: 'Waiting for Funds',
      );

  String get inProcess => Intl.message(
        'In Process',
        name: 'inProcess',
        desc: 'In Process',
      );

  String get cancelled => Intl.message(
        'Cancelled',
        name: 'cancelled',
        desc: 'Cancelled',
      );

  String get cancel => Intl.message(
        'Cancel',
        name: 'cancel',
        desc: 'Cancel',
      );

  String get status => Intl.message(
        'Status',
        name: 'status',
        desc: 'Status',
      );

  String get contactNameDialogTitle => Intl.message(
        'Contact Name',
        name: 'contactNameDialogTitle',
        desc: 'Contact Name Alert Dialog Title',
      );

  String get changeNameTitle => Intl.message(
        'Change Name',
        name: 'changeNameTitle',
        desc: 'Change Name Alert Dialog Title',
      );

  String get contactName => Intl.message(
        'Name',
        name: 'contactName',
        desc: 'Contact Name',
      );

  String get profilePageTitle => Intl.message(
        'Profile',
        name: 'profilePageTitle',
        desc: 'Profile Page Title',
      );

  String get shareProfile => Intl.message(
        'Share',
        name: 'shareProfile',
        desc: 'Share Profile',
      );

  String get saveContactTitle => Intl.message(
        'Save Proxy',
        name: 'saveContactTitle',
        desc: 'Save Proxy Page Title',
      );

  String get insufficientFundsStatus => Intl.message(
        'No Funds',
        name: 'insufficientFundsStatus',
        desc: 'No Funds',
      );

  String get cancelledStatus => Intl.message(
        'Cancelled',
        name: 'cancelledStatus',
        desc: 'Cancelled',
      );

  String get cancelledByPayerStatus => Intl.message(
        'No Funds',
        name: 'cancelledByPayerStatus',
        desc: 'No Funds',
      );

  String get cancelledByPayeeStatus => Intl.message(
        'No Funds',
        name: 'cancelledByPayeeStatus',
        desc: 'No Funds',
      );

  String get processedStatus => Intl.message(
        'No Funds',
        name: 'processedStatus',
        desc: 'No Funds',
      );

  String get expiredStatus => Intl.message(
        'Expired',
        name: 'expiredStatus',
        desc: 'Status for Expired',
      );

  String get errorStatus => Intl.message(
        'Error',
        name: 'errorStatus',
        desc: 'Status for Error',
      );

  String get outwardPaymentToUnknownEventSubTitle => Intl.message(
        'Waiting for Payee to Accept',
        name: 'outwardPaymentToUnknownEventSubTitle',
        desc: 'Waiting for Payee to Accept payment',
      );

  String inwardPaymentEventSubTitle(String payer) {
    return Intl.message(
      'From: $payer',
      name: 'inwardPaymentEventSubTitle',
      args: [payer],
      desc: 'Payment from payer',
      examples: {
        'payer': 'abcd-defghij',
      },
    );
  }

  String outwardPaymentEventSubTitle(String payee) {
    return Intl.message(
      'To: $payee',
      name: 'outwardPaymentEventSubTitle',
      args: [payee],
      desc: 'Payment to Payee',
      examples: {
        'payee': 'abcd-defghij',
      },
    );
  }

  String get message => Intl.message(
        'Message',
        name: 'message',
        desc: 'Message',
      );

  String get secret => Intl.message(
        'Secret',
        name: 'secret',
        desc: 'Secret',
      );

  String get eventDeleted => Intl.message(
        'Deleted',
        name: 'eventDeleted',
        desc: 'Event Deleted',
      );

  String addMeToYourContacts(String link) {
    return Intl.message(
      'Add me to your contacts $link',
      name: 'addMeToYourContacts',
      args: [link],
      desc: 'Add to contacts using given link',
      examples: {
        'link': 'abcd-defghij',
      },
    );
  }

  String acceptPayment(String link) {
    return Intl.message(
      'Accept Payment $link',
      name: 'acceptPayment',
      args: [link],
      desc: 'Accept Payment through the link',
      examples: {
        'link': 'abcd-defghij',
      },
    );
  }

  String get shareProfileDescription => Intl.message(
        'Add Proxy Id to Contacts',
        name: 'shareProfileDescription',
        desc: 'Description for Share Profile Action',
      );

  String get shareProfileTitle => Intl.message(
        'Proxy Id',
        name: 'shareProfileTitle',
        desc: 'Title for Share Profile Action',
      );

  String get sharePaymentDescription => Intl.message(
        'Accept Payment',
        name: 'sharePaymentDescription',
        desc: 'Description for Share Payment Action',
      );

  String get sharePaymentTitle => Intl.message(
        'Payment',
        name: 'sharePaymentTitle',
        desc: 'Title for Share Payment Action',
      );

  String get acceptPaymentPageTitle => Intl.message(
        'Accept Payment',
        name: 'acceptPaymentPageTitle',
        desc: 'Page title to accept payment',
      );

  String get invalidPayment => Intl.message(
        'Invalid Payment',
        name: 'invalidPayment',
        desc: 'Invalid Payment',
      );

  String get enterSecretCode => Intl.message(
        'Enter Secret',
        name: 'enterSecretCode',
        desc: 'Enter Secret',
      );

  String get acceptPaymentButtonLabel => Intl.message(
        'Accept',
        name: 'acceptPaymentButtonLabel',
        desc: 'Accept Payment Button Label',
      );

  String get closeButtonLabel => Intl.message(
        'Close',
        name: 'closeButtonLabel',
        desc: 'Close Button Label',
      );

  String get paymentCanNotBeAccepted => Intl.message(
        'Payment can not be Accepted',
        name: 'paymentCanNotBeAccepted',
        desc: 'Payment can not be Accepted',
      );

  String get invalidSecret => Intl.message(
        'Invalid Secret',
        name: 'invalidSecret',
        desc: 'Invalid Secret',
      );

  String get depositNotFound => Intl.message(
        'Deposit not found',
        name: 'depositNotFound',
        desc: 'Deposit not found',
      );

  String amountDisplayMessage({double value, String currency}) => Intl.message(
        '$value $currency',
        name: 'amountDisplayMessage',
        args: [value, currency],
        desc: 'Amount as String',
      );

  String get shareDeposit => Intl.message('Share');

  String get loginPageTitle => Intl.message('Login');

  String get loginButtonLabel => Intl.message('Login');

  String get emailInputLabel => Intl.message('Email');

  String get loginPageDescription {
    return Intl.message(
      'Please verify your email address before proceeding further.',
    );
  }

  String get loginFailedMessage => Intl.message('Login Failed');

  String get checkYourMailForLoginLink => Intl.message('Mail sent with login link, login through the link.');

  String get cancelButtonLabel => Intl.message('Cancel');

  String get payButtonLabel => Intl.message('Pay');

  String get created => Intl.message('Created');

  String get withdrawalNotFound => Intl.message('Withdrawal not found');

  String get paymentAuthorizationEventTitle => Intl.message('Payment Sent');

  String paymentAuthorizationEventSubTitle(String payerAccount) {
    return Intl.message(
      'Account: $payerAccount',
      name: 'paymentAuthorizationEventSubTitle',
      args: [payerAccount],
      desc: 'Paying from Account',
      examples: {
        'payerAccount': 'NL11INGB040037899',
      },
    );
  }

  String get paymentAuthorizationNotFound => Intl.message('Payment Authorization not found');

  String get somethingWentWrong => Intl.message('Something went wrong');

  String get noDataAvailable => Intl.message('no data available');
}

class ProxyLocalizationsDelegate extends LocalizationsDelegate<ProxyLocalizations> {
  const ProxyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'nl', 'te'].contains(locale.languageCode);

  @override
  Future<ProxyLocalizations> load(Locale locale) => ProxyLocalizations.load(locale);

  @override
  bool shouldReload(ProxyLocalizationsDelegate old) => false;
}
