import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:promo/localizations.dart';
import 'package:promo/model/email_authorization_entity.dart';
import 'package:promo/model/phone_number_authorization_entity.dart';

class AuthorizationCard extends StatelessWidget {
  final PhoneNumberAuthorizationEntity phoneNumberAuthorization;
  final EmailAuthorizationEntity emailAuthorization;

  const AuthorizationCard({Key key, this.phoneNumberAuthorization, this.emailAuthorization}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return makeCard(context);
  }

  Widget makeCard(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
            // color: Color.fromRGBO(64, 75, 96, .9),
            ),
        child: makeListTile(context),
      ),
    );
  }

  String title(ProxyLocalizations localizations) {
    if (phoneNumberAuthorization != null) {
      return localizations.customerPhone;
    } else {
      return localizations.customerEmail;
    }
  }

  String subtitle(ProxyLocalizations localizations) {
    if (phoneNumberAuthorization != null) {
      return phoneNumberAuthorization.phoneNumber;
    } else {
      return emailAuthorization.email;
    }
  }

  IconData icon(ProxyLocalizations localizations) {
    if (phoneNumberAuthorization != null) {
      if (phoneNumberAuthorization.authorized) {
        if (Platform.isIOS) {
          return Icons.phone_iphone;
        } else {
          return Icons.phone_android;
        }
      }
    } else {
      if (emailAuthorization.authorized) {
        return Icons.email;
      }
    }
    return Icons.warning;
  }

  Widget makeListTile(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        title(localizations),
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          subtitle(localizations),
        ),
      ),
      trailing: Icon(
        icon(localizations),
      ),
    );
  }
}
