import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/db/phone_number_authorization_store.dart';
import 'package:proxy_flutter/model/phone_number_authorization_entity.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/authorization.dart';
import 'package:uuid/uuid.dart';

import 'service_helper.dart';

class PhoneNumberAuthorizationService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;

  final PhoneNumberAuthorizationStore _phoneNumberAuthorizationStore;
  final CryptographyService cryptographyService;

  final HttpClientFactory httpClientFactory;

  final Uuid uuidFactory = Uuid();
  final String appBackendUrl;

  PhoneNumberAuthorizationService(
    this.appConfiguration, {
    @required this.cryptographyService,
    HttpClientFactory httpClientFactory,
    String appBackendUrl,
  })  : _phoneNumberAuthorizationStore = PhoneNumberAuthorizationStore(appConfiguration),
        appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client;

  Future<PhoneNumberAuthorizationEntity> authorizePhoneNumber(String phoneNumber) async {
    PhoneNumberAuthorizationRequest request = PhoneNumberAuthorizationRequest(
      authorizationId: uuidFactory.v4(),
      requesterProxyId: appConfiguration.masterProxyId,
      phoneNumber: phoneNumber,
      authorizerProxyId: Constants.PROXY_APP_BACKEND_PROXY_ID,
    );

    final signedRequest = await signMessage(
      signer: request.requesterProxyId,
      request: request,
    );
    final signedChallenge = await sendAndReceive(
      url: appBackendUrl,
      signedRequest: signedRequest,
      responseParser: PhoneNumberAuthorizationChallenge.fromJson,
    );
    PhoneNumberAuthorizationEntity authorizationEntity = PhoneNumberAuthorizationEntity(
      authorizationId: request.requestId,
      proxyId: request.requesterProxyId,
      phoneNumber: phoneNumber,
      challenge: signedChallenge,
      authorized: false,
    );
    await _phoneNumberAuthorizationStore.saveAuthorization(authorizationEntity);
    // print("Received $signedResponse from $appBackendUrl");
    return authorizationEntity;
  }

  Future<PhoneNumberAuthorizationEntity> verifyAuthorizationChallenge({
    @required PhoneNumberAuthorizationEntity authorizationEntity,
    @required String secret,
  }) async {
    bool validSecret = await cryptographyService.verifyHash(
      hashValue: authorizationEntity.challenge.message.challengeHash,
      input: secret,
    );
    if (!validSecret) {
      print("Invalid Secret $secret for authorization $authorizationEntity");
      return null;
    }
    PhoneNumberAuthorizationChallengeResponse challengeResponse = PhoneNumberAuthorizationChallengeResponse(
      challenge: authorizationEntity.challenge,
      response: secret,
    );
    final signedRequest = await signMessage(
      signer: authorizationEntity.proxyId,
      request: challengeResponse,
    );
    final signedAuthorization = await sendAndReceive(
      url: appBackendUrl,
      signedRequest: signedRequest,
      responseParser: PhoneNumberAuthorization.fromJson,
    );
    authorizationEntity = authorizationEntity.copy(
      authorized: true,
      authorization: signedAuthorization,
      validFrom: signedAuthorization.message.validFrom,
      validTill: signedAuthorization.message.validTill,
    );
    print("Saving authorization $authorizationEntity to db");
    await _phoneNumberAuthorizationStore.saveAuthorization(authorizationEntity);
    return authorizationEntity;
  }
}