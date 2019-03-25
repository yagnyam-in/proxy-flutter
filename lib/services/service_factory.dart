import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/services/banking_service.dart';
import 'package:proxy_flutter/services/cryptography_service_impl.dart';
import 'package:proxy_flutter/services/notification_service.dart';

class ServiceFactory {
  static final NotificationService _notificationServiceInstance =
      NotificationService(messageSigningService: messageSigningService());

  static NotificationService notificationService() => _notificationServiceInstance;

  static CryptographyService cryptographyService() {
    return CryptographyServiceImpl();
  }

  static ProxyResolver proxyResolver() {
    return new RemoteProxyResolver();
  }

  static MessageVerificationService messageVerificationService() {
    return new MessageVerificationService(cryptographyService: cryptographyService(), proxyResolver: proxyResolver());
  }

  static MessageBuilder messageBuilder() {
    return MessageBuilder();
  }

  static MessageFactory messageFactory() {
    return MessageFactory(messageBuilder: messageBuilder(), messageVerificationService: messageVerificationService());
  }

  static MessageSigningService messageSigningService() {
    return MessageSigningService(cryptographyService: cryptographyService());
  }

  static ProxyKeyRepo proxyKeyRepo() {
    return ProxyKeyRepo.instance(DB.instance());
  }

  static ProxyAccountRepo proxyAccountRepo() {
    return ProxyAccountRepo.instance(DB.instance());
  }

  static BankingService bankingService() {
    return BankingService(
      messageFactory: messageFactory(),
      messageSigningService: messageSigningService(),
      proxyAccountRepo: proxyAccountRepo(),
      proxyKeyRepo: proxyKeyRepo(),
    );
  }

  static ProxyIdFactory proxyIdFactory() => ProxyIdFactory.instance();
}
