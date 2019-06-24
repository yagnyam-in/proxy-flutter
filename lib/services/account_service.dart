import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/account_store.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/db/proxy_store.dart';
import 'package:proxy_flutter/model/account_entity.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';

class AccountRequest {
  final String encryptionKey;

  AccountRequest({
    @required this.encryptionKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'encryptionKey': encryptionKey,
    };
  }

  factory AccountRequest.fromJson(Map json) {
    return AccountRequest(
      encryptionKey: json['encryptionKey'] as String,
    );
  }
}

class AccountResponse {
  final String accountId;
  final String accountIdHmac;

  AccountResponse({
    @required this.accountId,
    @required this.accountIdHmac,
  });

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountIdHmac': accountIdHmac,
    };
  }

  factory AccountResponse.fromJson(Map json) {
    return AccountResponse(
      accountId: json['accountId'] as String,
      accountIdHmac: json['accountIdHmac'] as String,
    );
  }
}

class AccountService with ProxyUtils, HttpClientUtils, DebugUtils {
  final FirebaseUser firebaseUser;
  final UserEntity appUser;
  final HttpClientFactory httpClientFactory;
  final String appBackendUrl;
  final ProxyVersion proxyVersion = ProxyVersion.latestVersion();
  final ProxyFactory proxyFactory = ProxyFactory();

  AccountService({
    @required this.firebaseUser,
    @required this.appUser,
    HttpClientFactory httpClientFactory,
    String appBackendUrl,
  })  : httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        appBackendUrl = "${appBackendUrl ?? UrlConfig.APP_BACKEND}/app/accounts" {
    assert(firebaseUser != null);
    assert(appUser != null);
  }

  Future<AccountEntity> createAccount({@required String encryptionKey}) async {
    AccountRequest request = AccountRequest(
      encryptionKey: encryptionKey,
    );
    String response = await post(
      httpClientFactory(),
      appBackendUrl,
      body: jsonEncode(request.toJson()),
      basicAuthorization: _basicAuthorizationHeader(),
    );
    AccountResponse accountResponse = AccountResponse.fromJson(jsonDecode(response));
    return AccountEntity(
      accountId: accountResponse.accountId,
      accountIdHmac: accountResponse.accountIdHmac,
    );
  }

  Future<bool> validateEncryptionKey({
    @required AccountEntity account,
    @required String encryptionKey,
  }) async {
    if (isEmpty(encryptionKey)) {
      return false;
    }
    print("Checking HAMC for ${account.accountId}");
    String accountIdHmac = await ServiceFactory.cryptographyService.getHmac(
      hmacAlgorithm: "HmacSHA256",
      input: account.accountId,
      key: encryptionKey,
    );
    if (accountIdHmac != account.accountIdHmac) {
      print("$accountIdHmac != ${account.accountIdHmac}");
      return false;
    }
    return true;
  }

  Future<AccountEntity> setupMasterProxy(AccountEntity account) async {
    print("_setupMasterProxy");
    String proxyId = ProxyIdFactory.instance().proxyId();
    ProxyKey proxyKey = await _createProxyKey(proxyId);
    ProxyRequest proxyRequest = await _createProxyRequest(
      proxyKey,
      AppConfiguration.passPhrase,
    );
    Proxy proxy = await _createProxy(proxyRequest);
    proxyKey = proxyKey.copyWith(id: proxy.id);
    await ProxyKeyStore(account).insertProxyKey(proxyKey);
    await ProxyStore(account).insertProxy(proxy);
    account = await AccountStore().saveAccount(account.copy(masterProxyId: proxy.id));
    return account;
  }

  String _basicAuthorizationHeader() {
    return base64Encode(utf8.encode("${appUser.uid}:${appUser.password}"));
  }

  Future<ProxyKey> _createProxyKey(String proxyId) {
    print("createProxyKey");
    return ServiceFactory.proxyKeyFactory.createProxyKey(
      id: proxyId,
      keyGenerationAlgorithm: proxyVersion.keyGenerationAlgorithm,
      keySize: proxyVersion.keySize,
    );
  }

  Future<ProxyRequest> _createProxyRequest(
    ProxyKey proxyKey,
    String revocationPassPhrase,
  ) {
    print("createProxyRequest");
    return ServiceFactory.proxyRequestFactory.createProxyRequest(
      proxyKey: proxyKey,
      signatureAlgorithm: proxyVersion.certificateSignatureAlgorithm,
      revocationPassPhrase: revocationPassPhrase,
    );
  }

  Future<Proxy> _createProxy(ProxyRequest proxyRequest) {
    print("createProxy");
    Future<Proxy> proxy = proxyFactory.createProxy(proxyRequest);
    return proxy;
  }
}
