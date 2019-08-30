import 'package:flutter/cupertino.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/dismissed_enticement_store.dart';
import 'package:proxy_flutter/model/dismissed_enticement_entity.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';

class EnticementService {
  final AppConfiguration appConfiguration;
  final DismissedEnticementStore _dismissedEnticementStore;
  final EnticementFactory _enticementFactory;

  EnticementService(this.appConfiguration)
      : _dismissedEnticementStore = DismissedEnticementStore(appConfiguration),
        _enticementFactory = EnticementFactory() {
    assert(appConfiguration != null);
  }

  Stream<Enticement> subscribeForEnticement() {
    return subscribeForEnticements().map((l) => l.first);
  }

  Stream<List<Enticement>> subscribeForEnticements() {
    List<Enticement> all = _enticementFactory.getEnticements(appConfiguration.proxyUniverse);
    print("All Enticements => $all");
    Stream<List<DismissedEnticementEntity>> dismissed = _dismissedEnticementStore.subscribeForEnticements();
    return dismissed.map((dismissed) => _filterActiveEnticements(all, dismissed));
  }

  Stream<List<Enticement>> subscribeForFirstEnticement() {
    return subscribeForEnticements().map((l) => l.take(1).toList());
  }

  Future<void> dismissEnticement({
    @required String proxyUniverse,
    @required String enticementId,
  }) {
    return _dismissedEnticementStore.saveEnticement(DismissedEnticementEntity(
      id: enticementId,
      proxyUniverse: proxyUniverse,
    ));
  }

  Future<void> dismissEnticements({
    @required String enticementId,
  }) async {
    final allUniverses = [ProxyUniverse.PRODUCTION, ProxyUniverse.TEST];
    final allRequests = allUniverses.map((u) => _dismissedEnticementStore.saveEnticement(DismissedEnticementEntity(
      id: enticementId,
      proxyUniverse: u,
    )));
    Future.wait(allRequests);
  }


  List<Enticement> _filterActiveEnticements(List<Enticement> all, List<DismissedEnticementEntity> dismissed) {
    return all
        .skipWhile((e) => dismissed.any((d) => d.id == e.id && e.proxyUniverses.contains(d.proxyUniverse)))
        .toList();
  }
}
