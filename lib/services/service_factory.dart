import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/boot_service.dart';
import 'package:proxy_flutter/services/local_proxy_resolver.dart';
import 'package:proxy_flutter/services/native_cryptography_service_impl.dart';
import 'package:proxy_flutter/services/notification_service.dart';

import 'deep_link_service.dart';

class ServiceFactory {
  static final NotificationService _notificationServiceInstance =
      NotificationService(messageSigningService: messageSigningService());

  static NotificationService notificationService() => _notificationServiceInstance;

  static ProxyResolver proxyResolver(AppConfiguration appConfiguration) => CachedProxyResolver(
        proxyResolver: LocalProxyResolver(
          appConfiguration,
          remoteProxyResolver: RemoteProxyResolver(),
        ),
      );

  static CryptographyService cryptographyService() {
    return NativeCryptographyServiceImpl();
  }

  static MessageVerificationService messageVerificationService(AppConfiguration appConfiguration) {
    return new MessageVerificationService(
      cryptographyService: cryptographyService(),
      proxyResolver: proxyResolver(appConfiguration),
    );
  }

  static MessageBuilder messageBuilder() {
    return MessageBuilder();
  }

  static MessageFactory messageFactory(AppConfiguration appConfiguration) {
    return MessageFactory(
      messageBuilder: messageBuilder(),
      messageVerificationService: messageVerificationService(appConfiguration),
    );
  }

  static MessageSigningService messageSigningService() {
    return MessageSigningService(cryptographyService: cryptographyService());
  }

  static ProxyIdFactory proxyIdFactory() => ProxyIdFactory.instance();

  static DeepLinkService deepLinkService() {
    return DeepLinkService();
  }

  static final BootService _bootServiceInstance = BootService();

  static BootService bootService() => _bootServiceInstance;
}
