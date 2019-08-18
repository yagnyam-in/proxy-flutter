import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/services/service_factory.dart';

typedef SignedMessageParser<T extends SignableMessage> = SignedMessage<T> Function(Map json);

class SignedRequestResponse<T extends SignableMessage, R extends SignableMessage> {
  final SignedMessage<T> request;
  final SignedMessage<R> response;

  SignedRequestResponse({
    @required this.request,
    @required this.response,
  });
}

mixin ServiceHelper on ProxyUtils, HttpClientUtils {
  HttpClientFactory get httpClientFactory;

  AppConfiguration get appConfiguration;

  Future<SignedMessage<T>> signMessage<T extends SignableMessage>({
    @required T request,
  }) async {
    ProxyKey proxyKey = await ProxyKeyStore(appConfiguration).fetchProxyKey(appConfiguration.masterProxyId);
    return ServiceFactory.messageSigningService().sign(
      request,
      proxyKey,
    );
  }

  Future<SignedMessage<R>> sendAndReceive<T extends SignableMessage, R extends SignableMessage>({
    @required String url,
    @required SignedMessage<T> signedRequest,
    @required SignableMessageFromJsonMethod<R> responseParser,
  }) async {
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    // print("Sending $signedRequestJson to $url");
    String jsonResponse = await post(
      httpClientFactory(),
      url,
      body: signedRequestJson,
    );
    // print("Received $jsonResponse from $url");
    return ServiceFactory.messageFactory(appConfiguration).buildAndVerifySignedMessage(
      jsonResponse,
      responseParser,
    );
  }
}
