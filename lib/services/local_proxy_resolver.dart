import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/db/proxy_repo.dart';

class LocalProxyResolver extends ProxyResolver {
  final RemoteProxyResolver remoteProxyResolver;

  final ProxyRepo proxyRepo;

  LocalProxyResolver({
    @required this.remoteProxyResolver,
    @required this.proxyRepo,
  });

  @override
  Future<Proxy> resolveProxy(ProxyId proxyId) async {
    Proxy proxy = await proxyRepo.fetchProxy(proxyId);
    if (proxy == null) {
      proxy = await remoteProxyResolver.resolveProxy(proxyId);
      await proxyRepo.insert(proxy);
    }
    return proxy;
  }
}
