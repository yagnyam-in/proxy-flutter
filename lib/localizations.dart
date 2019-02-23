import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_all.dart';

class ProxyLocalizations {
  static Future<ProxyLocalizations> load(Locale locale) {
    final String name =
        locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
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
      'Proxy Term & Conditions',
      name: 'termsAndConditionsPageTitle',
      desc: 'Page title for accepting proxy terms & conditions',
    );
  }


  String get readTermsAndConditions {
    return Intl.message(
      'Before accepting, please go through full Terms & Conditions at ',
      name: 'readTermsAndConditions',
      desc: 'I agree terms & conditions',
    );
  }

  String get termsAndConditionsURL {
    return Intl.message(
      'https://proxy.yagnyam.in/tc',
      name: 'termsAndConditionsURL',
      desc: 'Proxy Terms & Conditions URL',
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
      }
    );
  }



}

class ProxyLocalizationsDelegate
    extends LocalizationsDelegate<ProxyLocalizations> {
  const ProxyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'nl', 'te'].contains(locale.languageCode);

  @override
  Future<ProxyLocalizations> load(Locale locale) =>
      ProxyLocalizations.load(locale);

  @override
  bool shouldReload(ProxyLocalizationsDelegate old) => false;
}
