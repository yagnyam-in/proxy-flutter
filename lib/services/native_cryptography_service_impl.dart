import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class NativeCryptographyServiceImpl extends CryptographyService {
  static const platform = const MethodChannel('proxy.yagnyam.in/CryptographyService');

  @override
  Future<String> decrypt({
    ProxyKey proxyKey,
    String encryptionAlgorithm,
    String cipherText,
  }) async {
    return platform.invokeMethod('decrypt', {
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
    return platform.invokeMethod('encrypt', {
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
  }) async {
    Map<dynamic, dynamic> result = await platform.invokeMethod('getSignatures', {
      'proxyKey': jsonEncode(proxyKey.toJson()),
      'input': input,
      'algorithms': signatureAlgorithms.toList(),
    });
    print(result);
    Map<String, String> signatures = Map();
    result.forEach((k, v) => signatures[k] = v.toString());
    return signatures;
  }

  @override
  Future<bool> verifySignatures({
    Proxy proxy,
    String input,
    Map<String, String> signatures,
  }) async {
    bool valid = await platform.invokeMethod('verifySignatures', {
      'proxy': jsonEncode(proxy.toJson()),
      'input': input,
      'signatures': signatures,
    });
    return valid;
  }

  @override
  Future<String> getHash({
    String hashAlgorithm,
    String input,
  }) async {
    return platform.invokeMethod('hash', {
      'input': input,
      'hashAlgorithm': hashAlgorithm,
    });
  }
}
