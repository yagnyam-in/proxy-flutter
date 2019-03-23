import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class ProxyKeyStoreImpl implements ProxyRequestFactory, ProxyKeyFactory {
  static const platform = const MethodChannel('proxy.yagnyam.in/ProxyKeyStore');

  @override
  Future<ProxyKey> createProxyKey({
    String id,
    String keyGenerationAlgorithm,
    int keySize,
  }) async {
    final String result = await platform.invokeMethod('createProxyKey', {
      "id": id,
      "keyGenerationAlgorithm": keyGenerationAlgorithm,
      "keySize": "$keySize",
    });
    return ProxyKey.fromJson(jsonDecode(result));
  }

  @override
  Future<ProxyRequest> createProxyRequest({
    ProxyKey proxyKey,
    String signatureAlgorithm,
    String revocationPassPhrase,
  }) async {
    final String result = await platform.invokeMethod('createProxyRequest', {
      "proxyKey": jsonEncode(proxyKey.toJson()),
      "signatureAlgorithm": signatureAlgorithm,
      "revocationPassPhrase": revocationPassPhrase,
    });
    return ProxyRequest.fromJson(jsonDecode(result));
  }


  Future<void> saveProxy({
    ProxyKey proxyKey,
    Proxy proxy,
  }) {
    return platform.invokeMethod('saveProxy', {
      "proxyKey": jsonEncode(proxyKey.toJson()),
      "proxy": jsonEncode(proxy.toJson()),
    });
  }
}
