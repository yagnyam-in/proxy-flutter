import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';

import 'authorize_phone_number_page.dart';
import 'config/app_configuration.dart';
import 'localizations.dart';
import 'model/phone_number_authorization_entity.dart';
import 'services/service_factory.dart';
import 'widgets/basic_types.dart';

mixin AuthorizationsHelper {
  AppConfiguration get appConfiguration;

  void showToast(String message);

  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  });

  Future<void> verifyPhoneNumber(BuildContext context, String phoneNumber) async {
    if (isNotBlank(phoneNumber)) {
      print("Verify Phone Number $phoneNumber");
      PhoneNumberAuthorizationEntity authorization = await invoke(
        () => ServiceFactory.phoneNumberAuthorizationService(appConfiguration).authorizePhoneNumber(phoneNumber),
        name: "Verify Phone Number",
        onError: () => showToast(ProxyLocalizations.of(context).somethingWentWrong),
      );
      if (authorization != null) {
        print("Launching Phone Authorization Page");
        return Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (context) => AuthorizePhoneNumberPage.forAuthorization(
              appConfiguration,
              authorization,
            ),
            fullscreenDialog: true,
          ),
        );
      }
    }
  }

  Future<void> verifyEmail(BuildContext context, String email) async {
    print("Verify Email");
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (isNotEmpty(email)) {
      invoke(() async {
        await ServiceFactory.emailAuthorizationService(appConfiguration).authorizeEmailAddress(email);
        showToast(localizations.followMailInstructions);
      }, name: "Verify Email");
    }
  }
}
