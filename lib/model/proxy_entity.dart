import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

class ProxyEntity {
  final ProxyId proxyId;

  final String proxyEncoded;

  DateTime lastUpdated;

  ProxyEntity({@required this.proxyId, @required this.proxyEncoded, this.lastUpdated});
}
