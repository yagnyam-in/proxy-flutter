import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_store.dart';

class LocalProxyResolver extends ProxyResolver {
  final AppConfiguration appConfiguration;
  final RemoteProxyResolver remoteProxyResolver;

  final ProxyStore _proxyStore;

  LocalProxyResolver(
    this.appConfiguration, {
    @required this.remoteProxyResolver,
  }) : _proxyStore = ProxyStore(appConfiguration);

  @override
  Future<Proxy> resolveProxy(ProxyId proxyId) async {
    Proxy proxy = await _proxyStore.fetchProxy(proxyId);
    if (proxy == null) {
      proxy = await remoteProxyResolver.resolveProxy(proxyId);
      if (proxy != null) {
        await _proxyStore.insertProxy(proxy);
      }
    }
    return proxy;
  }
}
