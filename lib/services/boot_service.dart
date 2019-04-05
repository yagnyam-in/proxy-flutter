import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';

class BootService with ProxyUtils, HttpClientUtils, DebugUtils {
  final String proxyCentralHealthCheck;
  final String proxyBankingHealthCheck;
  final HttpClientFactory httpClientFactory;

  bool _started = false;

  BootService({
    String proxyCentralHealthCheck,
    String proxyBankingHealthCheck,
    HttpClientFactory httpClientFactory,
  })  : proxyCentralHealthCheck = proxyCentralHealthCheck ?? "https://proxy-cs.appspot.com/health-check",
        proxyBankingHealthCheck = proxyBankingHealthCheck ?? "https://proxy-banking.appspot.com/health-check",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyCentralHealthCheck));
  }

  void start() {
    if (!_started) {
      _start();
      _started = true;
    }
  }

  void _start() {
    get(httpClientFactory(), proxyCentralHealthCheck).then((health) {
      print("Proxy Central Health Check $health");
    }, onError: (error) {
      print("Proxy Central Health Check $error");
    });
    get(httpClientFactory(), proxyBankingHealthCheck).then((health) {
      print("Proxy Banking Health Check $health");
    }, onError: (error) {
      print("Proxy Central Health Check $error");
    });

  }
}
