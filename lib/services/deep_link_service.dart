import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/constants.dart';
import 'package:promo/url_config.dart';

class DeepLinkService with ProxyUtils, HttpClientUtils, DebugUtils {
  final HttpClientFactory httpClientFactory;

  DeepLinkService({
    HttpClientFactory httpClientFactory,
  }) : httpClientFactory = httpClientFactory ?? ProxyHttpClient.client;

  Future<Uri> createDeepLink(
    Uri link, {
    String title,
    String description,
  }) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: UrlConfig.DYNAMIC_LINK_PREFIX,
      link: link,
      androidParameters: AndroidParameters(
        packageName: Constants.ANDROID_PACKAGE_NAME,
      ),
      iosParameters: IosParameters(
        bundleId: Constants.IOS_BUNDLE_ID,
        appStoreId: Constants.IOS_APP_STORE_ID,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        description: description,
      ),
    );
    final shortLink = await parameters.buildShortLink();
    return shortLink.shortUrl;
  }

  void performDiagnostics() {}
}
