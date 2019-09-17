import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/constants.dart';
import 'package:proxy_flutter/db/email_authorization_store.dart';
import 'package:proxy_flutter/model/email_authorization_entity.dart';
import 'package:proxy_flutter/services/account_service.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/authorization.dart';
import 'package:uuid/uuid.dart';

import 'service_helper.dart';

class EmailAuthorizationService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils {
  final AppConfiguration appConfiguration;

  final EmailAuthorizationStore _emailAuthorizationStore;
  final CryptographyService cryptographyService;

  final HttpClientFactory httpClientFactory;

  final Uuid uuidFactory = Uuid();
  final String appBackendUrl;

  EmailAuthorizationService(
    this.appConfiguration, {
    @required this.cryptographyService,
    HttpClientFactory httpClientFactory,
    String appBackendUrl,
  })  : _emailAuthorizationStore = EmailAuthorizationStore(appConfiguration),
        appBackendUrl = appBackendUrl ?? "${UrlConfig.APP_BACKEND}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client;

  Future<void> authorizeEmailAddress(String email) async {
    int verificationIndex = await AccountService.nextEmailVerificationIndex(appConfiguration);
    EmailAuthorizationRequest request = EmailAuthorizationRequest(
      authorizationId: uuidFactory.v4(),
      requesterProxyId: appConfiguration.masterProxyId,
      email: email,
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
      responseParser: EmailAuthorizationChallenge.fromJson,
    );
    EmailAuthorizationEntity authorizationEntity = EmailAuthorizationEntity(
      authorizationId: request.requestId,
      proxyId: request.requesterProxyId,
      email: email,
      challenge: signedChallenge,
      verificationIndex: "$verificationIndex",
      authorized: false,
    );
    await _emailAuthorizationStore.saveAuthorization(authorizationEntity);
    // print("Received $signedResponse from $appBackendUrl");
  }

  Future<EmailAuthorizationEntity> verifyAuthorizationChallenge({
    @required EmailAuthorizationEntity authorizationEntity,
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
    EmailAuthorizationChallengeResponse challengeResponse = EmailAuthorizationChallengeResponse(
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
      responseParser: EmailAuthorization.fromJson,
    );
    authorizationEntity = authorizationEntity.copy(
      authorized: true,
      authorization: signedAuthorization,
      validFrom: signedAuthorization.message.validFrom,
      validTill: signedAuthorization.message.validTill,
    );
    print("Saving authorization $authorizationEntity to db");
    await _emailAuthorizationStore.saveAuthorization(authorizationEntity);
    return authorizationEntity;
  }

  Future<void> authorizeEmailIfNotAuthorized(String email) async {
    final authorization = await _emailAuthorizationStore.fetchActiveAuthorizationByEmail(
      email: email,
      proxyId: appConfiguration.masterProxyId,
    );
    if (authorization != null) {
      print("$email is alraedy authorized.");
      return;
    }
    authorizeEmailAddress(email);
  }
}
