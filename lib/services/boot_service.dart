import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class BootService with ProxyUtils, HttpClientUtils, DebugUtils {
  final String backendHealthCheck;
  final HttpClientFactory httpClientFactory;

  bool _started = false;

  BootService({
    String proxyCentralHealthCheck,
    String proxyBankingHealthCheck,
    HttpClientFactory httpClientFactory,
  })  : backendHealthCheck = proxyCentralHealthCheck ?? "https://app.pxy.yagnyam.in/health-check",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.backendHealthCheck));
  }

  void start() {
    if (!_started) {
      _start();
      _started = true;
    }
  }

  void _start() {
    get(httpClientFactory(), backendHealthCheck).then((health) {
      print("Proxy Central Health Check $health");
    }, onError: (error) {
      print("Proxy Central Health Check $error");
    });
  }
}
