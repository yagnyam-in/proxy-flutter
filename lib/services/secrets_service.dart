import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/db/email_authorization_store.dart';
import 'package:proxy_flutter/db/phone_number_authorization_store.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/authorization.dart';
import 'package:uuid/uuid.dart';

import 'service_helper.dart';

class SecretsService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;
  final CryptographyService cryptographyService;
  final PhoneNumberAuthorizationStore _phoneNumberAuthorizationStore;
  final EmailAuthorizationStore _emailAuthorizationStore;
  final HttpClientFactory httpClientFactory;
  final Uuid uuidFactory = Uuid();
  final String appBackendUrl;

  SecretsService(
    this.appConfiguration, {
    @required this.cryptographyService,
    HttpClientFactory httpClientFactory,
    String appBackendUrl,
  })  : _phoneNumberAuthorizationStore = PhoneNumberAuthorizationStore(appConfiguration),
        _emailAuthorizationStore = EmailAuthorizationStore(appConfiguration),
        appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client;

  Future<String> fetchSecretForPhoneNumber(String phoneNumber, HashValue secretHash) async {
    final phoneAuthorization = await _phoneNumberAuthorizationStore.fetchActiveAuthorizationByPhoneNumber(
      phoneNumber: phoneNumber,
      proxyId: appConfiguration.masterProxyId,
    );
    if (phoneAuthorization == null) {
      return null;
    }
    FetchSecretForPhoneNumberRequest request = FetchSecretForPhoneNumberRequest(
      phoneNumberAuthorization: phoneAuthorization.authorization,
      secretHash: secretHash,
    );
    final signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      url: appBackendUrl,
      signedRequest: signedRequest,
      responseParser: FetchSecretForPhoneNumberResponse.fromJson,
    );
    return signedResponse.message.secret;
  }

  Future<String> fetchSecretForEmail(String email, HashValue secretHash) async {
    final authorizationEntity = await _emailAuthorizationStore.fetchActiveAuthorizationByEmail(
      email: email,
      proxyId: appConfiguration.masterProxyId,
    );
    if (authorizationEntity == null) {
      return null;
    }
    FetchSecretForEmailRequest request = FetchSecretForEmailRequest(
      emailAuthorization: authorizationEntity.authorization,
      secretHash: secretHash,
    );
    final signedRequest = await signMessage(request: request);
    final signedResponse = await sendAndReceive(
      url: appBackendUrl,
      signedRequest: signedRequest,
      responseParser: FetchSecretForEmailResponse.fromJson,
    );
    return signedResponse.message.secret;
  }

  Future<void> saveSecrets(
    List<SecretForPhoneNumberRecipient> secretsForPhoneNumberRecipients,
    List<SecretForEmailRecipient> secretsForEmailRecipients,
  ) async {
    SendSecretsRequest request = SendSecretsRequest(
      senderProxyId: appConfiguration.masterProxyId,
      routerProxyId: Constants.PROXY_APP_BACKEND_PROXY_ID,
      validFrom: DateTime.now().toUtc(),
      validTill: DateTime.now().toUtc().add(Duration(days: 30)),
      secretsForPhoneNumberRecipients: secretsForPhoneNumberRecipients,
      secretsForEmailRecipients: secretsForEmailRecipients,
    );
    final signedRequest = await signMessage(request: request);
    await send(
      url: appBackendUrl,
      signedRequest: signedRequest,
    );
  }
}
