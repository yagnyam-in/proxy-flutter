import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/db/contacts_repo.dart';
import 'package:proxy_flutter/db/customer_repo.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/db/proxy_account_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';
import 'package:proxy_flutter/services/boot_service.dart';
import 'package:proxy_flutter/services/contacts_bloc.dart';
import 'package:proxy_flutter/services/cryptography_service_impl.dart';
import 'package:proxy_flutter/services/enticement_bloc.dart';
import 'package:proxy_flutter/services/local_proxy_resolver.dart';
import 'package:proxy_flutter/services/notification_service.dart';

import 'deep_link_service.dart';

class ServiceFactory {
  static final NotificationService _notificationServiceInstance =
      NotificationService(messageSigningService: messageSigningService());

  static NotificationService notificationService() => _notificationServiceInstance;

  static final ProxyResolver _proxyResolverInstance = new CachedProxyResolver(
    proxyResolver: LocalProxyResolver(
      remoteProxyResolver: RemoteProxyResolver(),
      proxyRepo: ProxyRepo.instance(DB.instance()),
    ),
  );

  static ProxyResolver proxyResolver() => _proxyResolverInstance;

  static CryptographyService cryptographyService() {
    return CryptographyServiceImpl();
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

  static ProxyIdFactory proxyIdFactory() => ProxyIdFactory.instance();

  static EnticementRepo enticementRepo() {
    return EnticementRepo.instance(DB.instance());
  }

  static CustomerRepo customerRepo() {
    return CustomerRepo.instance(DB.instance());
  }

  static DeepLinkService deepLinkService() {
    return DeepLinkService();
  }

  static EnticementBloc enticementBloc() => EnticementBloc(enticementRepo: enticementRepo());

  static final BootService _bootServiceInstance = BootService();

  static BootService bootService() => _bootServiceInstance;

  static ContactsRepo contactsRepo() => ContactsRepo.instance(DB.instance());

  static final ContactsBloc _contactsBlocInstance = ContactsBloc(contactsRepo: contactsRepo());

  static ContactsBloc contactsBloc() => _contactsBlocInstance;
}
