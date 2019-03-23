import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/services/banking_service.dart';
import 'package:proxy_flutter/services/cryptography_service_impl.dart';
import 'package:uuid/uuid.dart';

class ServiceFactory {
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
    return new MessageSigningService(cryptographyService: cryptographyService());
  }


  static ProxyKeyRepo proxyKeyRepo() {
    return new ProxyKeyRepo.instance(DB.instance());
  }

  static ProxyAccountRepo proxyAccountRepo() {
    return new ProxyAccountRepo(DB.instance());
  }

  static BankingService bankingService() {
    return BankingService(
      messageFactory: messageFactory(),
      messageSigningService: messageSigningService(),
      proxyAccountRepo: proxyAccountRepo(),
    );
  }

  static ProxyIdFactory proxyIdFactory() => ProxyIdFactory.instance();

}
