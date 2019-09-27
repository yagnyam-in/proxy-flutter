import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:url_launcher/url_launcher.dart';

mixin UpgradeHelper {
  void showSnackBar(SnackBar snackbar);

  void _showToastWithAction(
    String message, {
    @required String actionLabel,
    @required VoidCallback action,
  }) {
    showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 15),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: action,
        ),
      ),
    );
  }

  void _showToast(String message) {
    showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void checkForUpdates(BuildContext context) async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    await remoteConfig.fetch(expiration: const Duration(hours: 1));
    final configChanged = await remoteConfig.activateFetched();
    if (!configChanged) {
      print("Remote Config not changed");
      // return;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final requiredBuildNumber = remoteConfig.getInt('minimumRequiredAppVersion');
    final currentBuildNumber = int.parse(packageInfo.buildNumber);

    if (currentBuildNumber < requiredBuildNumber) {
      print("App must be upgraded to $requiredBuildNumber");
      ProxyLocalizations localizations = ProxyLocalizations.of(context);
      final message = localizations.newVersionOfAppAvailable;
      final actionLabel = localizations.updateAppAction;
      _showToastWithAction(
        message,
        actionLabel: actionLabel,
        action: () => _upgradeApp(context),
      );
    }
  }

  void _upgradeApp(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (Platform.isAndroid) {
      _launchStore(
        context,
        storeName: localizations.androidPlayStoreName,
        url: Constants.ANDROID_PLAY_STORE_URL,
      );
    } else if (Platform.isIOS) {
      _launchStore(
        context,
        storeName: localizations.iosAppStoreName,
        url: Constants.IOS_APP_STORE_URL,
      );
    } else {
      _showToast(localizations.unsupportedPlatform);
    }
  }

  void _launchStore(
    BuildContext context, {
    @required String storeName,
    @required String url,
  }) async {
    if (await canLaunch(url)) {
      launch(url);
    } else {
      print("Can't launch $url");
      _showToast(ProxyLocalizations.of(context).upgradeOnStore(storeName));
    }
  }
}
