abstract class AbstractEntity<T> {
  static const ACTIVE = "active";

  String get internalId;

  String get proxyUniverse;

  T copyWithInternalId(String id);

  Map<String, dynamic> toJson();
}
