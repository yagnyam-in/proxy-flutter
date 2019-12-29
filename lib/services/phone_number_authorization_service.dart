import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/constants.dart';
import 'package:promo/db/phone_number_authorization_store.dart';
import 'package:promo/model/phone_number_authorization_entity.dart';
import 'package:promo/url_config.dart';
import 'package:proxy_messages/authorization.dart';
import 'package:uuid/uuid.dart';

import 'account_service.dart';
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
        httpClientFactory = httpClientFactory ?? HttpClientUtils.httpClient();

  Future<PhoneNumberAuthorizationEntity> authorizePhoneNumber(String phoneNumber) async {
    int verificationIndex = await AccountService.nextPhoneNumberVerificationIndex(appConfiguration);
    print("Triggering Verification for $phoneNumber with Challenge $verificationIndex");
    PhoneNumberAuthorizationRequest request = PhoneNumberAuthorizationRequest(
      authorizationId: uuidFactory.v4(),
      requesterProxyId: appConfiguration.masterProxyId,
      phoneNumber: phoneNumber,
      authorizerProxyId: Constants.PROXY_APP_BACKEND_PROXY_ID,
      index: "$verificationIndex",
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
    print("Received ${signedChallenge.message} from $appBackendUrl");
    PhoneNumberAuthorizationEntity authorizationEntity = PhoneNumberAuthorizationEntity(
      authorizationId: request.requestId,
      proxyId: request.requesterProxyId,
      phoneNumber: phoneNumber,
      challenge: signedChallenge,
      verificationIndex: "$verificationIndex",
      authorized: false,
    );
    await _phoneNumberAuthorizationStore.saveAuthorization(authorizationEntity);
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

  Future<void> authorizePhoneNumberIfNotAuthorized(String phoneNumber) async {
    final authorization = await _phoneNumberAuthorizationStore.fetchActiveAuthorizationByPhoneNumber(
      phoneNumber: phoneNumber,
      proxyId: appConfiguration.masterProxyId,
    );
    if (authorization != null) {
      print("$phoneNumber is alraedy authorized.");
      return;
    }
    authorizePhoneNumber(phoneNumber);
  }
}
