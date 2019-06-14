import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:proxy_flutter/model/enticement.dart';

part 'dismissed_enticement_entity.g.dart';

@JsonSerializable()
class DismissedEnticementEntity {
  @JsonKey(nullable: false)
  final String id;
  @JsonKey(nullable: false)
  final String proxyUniverse;

  DismissedEnticementEntity({
    @required this.id,
    @required this.proxyUniverse,
  });

  DismissedEnticementEntity.fromEnticement(Enticement enticement)
      : id = enticement.id,
        proxyUniverse = enticement.proxyUniverse;

  Map<String, dynamic> toJson() => _$DismissedEnticementEntityToJson(this);

  static DismissedEnticementEntity fromJson(Map json) => _$DismissedEnticementEntityFromJson(json);
}
