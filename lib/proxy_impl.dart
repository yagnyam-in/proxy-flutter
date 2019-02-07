import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:proxy_core/bootstrap.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class ProxyRequestFactoryImpl implements ProxyRequestFactory {
  static const platform = const MethodChannel('proxy.yagnyam.in/ProxyRequestFactory');

  @override
  Future<ProxyRequest> createProxyRequest(
      {String id,
      String signatureAlgorithm,
      String revocationPassPhrase,
      String keyGenerationAlgorithm,
      int keySize}) async {
    final String result = await platform.invokeMethod('createProxyRequest', {
      "id": id,
      "signatureAlgorithm": signatureAlgorithm,
      "revocationPassPhrase": revocationPassPhrase,
      "keyGenerationAlgorithm": keyGenerationAlgorithm,
      "keySize": "$keySize",
    });
    return ProxyRequest.fromJson(jsonDecode(result));
  }
}

class CryptographyServiceImpl extends CryptographyService {
  static const platform = const MethodChannel('proxy.yagnyam.in/CryptographyService');

  @override
  Future<String> decrypt({Proxy proxy, String encryptionAlgorithm, String cipherText}) async {
    return await platform.invokeMethod('decrypt', {
      'proxy': proxy.toJson(),
      'algorithm': encryptionAlgorithm,
      'input': cipherText,
    });
  }

  @override
  Future<String> encrypt({Proxy proxy, String encryptionAlgorithm, String input}) async {
    return await platform.invokeMethod('encrypt', {
      'proxy': proxy.toJson(),
      'algorithm': encryptionAlgorithm,
      'input': input,
    });
  }

  @override
  Future<Map<String, String>> getSignatures({Proxy proxy, String input, Set<String> signatureAlgorithms}) async {
    return await platform.invokeMethod('getSignatures', {
      'proxy': proxy.toJson(),
      'input': input,
      'algorithms': signatureAlgorithms.toList(),
    });
  }

  @override
  Future<bool> verifySignatures({Proxy proxy, String input, Map<String, String> signatures}) async {
    return await platform.invokeMethod('getSignatures', {
      'proxy': proxy.toJson(),
      'input': input,
      'signatures': signatures,
    });
  }
}
