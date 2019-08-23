import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Not required. But due to firestore limits (max 1 per 1 sec), we may not be able to update it just after it is created
  final HashValue encryptionKeyHash;

  AccountRequest({
    @required this.encryptionKeyHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'encryptionKeyHash': encryptionKeyHash.toJson(),
    };
  }

  @override
  String toString() {
    return "AccountRequest(encryptionKeyHash: $encryptionKeyHash)";
  }
}

class AccountResponse {
  final String accountId;

  AccountResponse({
    @required this.accountId,
  });

  @override
  String toString() {
    return "AccountResponse(accountId: $accountId)";
  }

  factory AccountResponse.fromJson(Map json) {
    return AccountResponse(
      accountId: json['accountId'] as String,
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

  factory AccountService.fromAppConfig(AppConfiguration appConfiguration) {
    return AccountService(
      firebaseUser: appConfiguration.firebaseUser,
      appUser: appConfiguration.appUser,
    );
  }

  Future<AccountEntity> createAccount({@required String encryptionKey}) async {
    AccountRequest request = AccountRequest(
      encryptionKeyHash: await ServiceFactory.cryptographyService.getHash(
        hashAlgorithm: 'SHA256',
        input: encryptionKey,
      ),
    );
    String response = await post(
      httpClientFactory(),
      appBackendUrl,
      body: jsonEncode(request.toJson()),
      bearerAuthorization: (await firebaseUser.getIdToken()).token,
    );
    AccountResponse accountResponse = AccountResponse.fromJson(jsonDecode(response));
    AccountEntity account = AccountEntity(
      accountId: accountResponse.accountId,
      encryptionKeyHash: request.encryptionKeyHash,
    );
    try {
      // Good to have. Not mandatory to save
      await AccountStore().saveAccount(account);
    } catch (e) {
      print("Failed to update Account $account: $e");
    }
    return account;
  }

  Future<bool> validateEncryptionKey({
    @required AccountEntity account,
    @required String encryptionKey,
  }) async {
    if (isEmpty(encryptionKey)) {
      return false;
    }
    print("Checking HAMC for ${account.accountId}");
    return ServiceFactory.cryptographyService.verifyHash(
      hashValue: account.encryptionKeyHash,
      input: encryptionKey,
    );
  }

  Future<bool> _hasValidMasterProxyId(AccountEntity account, String passPhrase) async {
    if (account.masterProxyId == null) {
      return false;
    }
    return await ProxyKeyStore.forAccount(account, passPhrase).hasProxyKey(account.masterProxyId);
  }

  Future<AccountEntity> setupMasterProxy(AccountEntity account, String passPhrase) async {
    print("_setupMasterProxy for $account");
    if (await _hasValidMasterProxyId(account, passPhrase)) {
      print('Already has Proxy setup. Re-using');
      return account;
    }
    String proxyId = ProxyIdFactory.instance().proxyId();
    ProxyKey proxyKey = await _createProxyKey(proxyId);
    ProxyRequest proxyRequest = await _createProxyRequest(
      proxyKey,
      passPhrase,
    );
    Proxy proxy = await _createProxy(proxyRequest);
    proxyKey = proxyKey.copyWith(id: proxy.id);
    await Firestore.instance.runTransaction((transaction) async {
      var keyFuture = ProxyKeyStore.forAccount(account, passPhrase).insertProxyKey(proxyKey, transaction: transaction);
      var proxyFuture = ProxyStore(account).insertProxy(proxy, transaction: transaction);
      var accountFuture = AccountStore().saveAccount(account.copy(masterProxyId: proxy.id), transaction: transaction);
      await Future.wait([keyFuture, proxyFuture, accountFuture]);
      return {};
    });
    return account;
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

  static Future<AccountEntity> updatePreferences(
    AppConfiguration appConfiguration,
    AccountEntity account, {
    String name,
    String currency,
    String email,
    String phone,
  }) async {
    AccountEntity updatedAccount = account.copy(
      name: name,
      email: email,
      phone: phone,
      preferredCurrency: currency,
    );
    await AccountStore().saveAccount(updatedAccount);
    appConfiguration.account = updatedAccount;
    return updatedAccount;
  }

  Future<Proxy> _createProxy(ProxyRequest proxyRequest) {
    print("createProxy");
    return proxyFactory.createProxy(proxyRequest);
  }
}
