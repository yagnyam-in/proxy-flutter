import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class CryptographyServiceImpl extends CryptographyService {
  static const platform = const MethodChannel('proxy.yagnyam.in/CryptographyService');

  @override
  Future<String> decrypt({
    ProxyKey proxyKey,
    String encryptionAlgorithm,
    String cipherText,
  }) async {
    return await platform.invokeMethod('decrypt', {
      'proxyKey': jsonEncode(proxyKey.toJson()),
      'algorithm': encryptionAlgorithm,
      'input': cipherText,
    });
  }

  @override
  Future<String> encrypt({
    Proxy proxy,
    String encryptionAlgorithm,
    String input,
  }) async {
    return await platform.invokeMethod('encrypt', {
      'proxy': jsonEncode(proxy.toJson()),
      'algorithm': encryptionAlgorithm,
      'input': input,
    });
  }

  @override
  Future<Map<String, String>> getSignatures({
    ProxyKey proxyKey,
    String input,
    Set<String> signatureAlgorithms,
  }) {
    return platform.invokeMethod('getSignatures', {
      'proxyKey': jsonEncode(proxyKey.toJson()),
      'input': input,
      'algorithms': signatureAlgorithms.toList(),
    });
  }

  @override
  Future<bool> verifySignatures({
    Proxy proxy,
    String input,
    Map<String, String> signatures,
  }) {
    return platform.invokeMethod('getSignatures', {
      'proxy': jsonEncode(proxy.toJson()),
      'input': input,
      'signatures': signatures,
    });
  }
}
