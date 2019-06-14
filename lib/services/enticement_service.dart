import 'package:flutter/cupertino.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/dismissed_enticement_store.dart';
import 'package:proxy_flutter/localizations.dart';
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

  Stream<List<Enticement>> subscribeForEnticements(ProxyLocalizations localizations) {
    Stream<List<DismissedEnticementEntity>> dismissed = _dismissedEnticementStore.subscribeForEnticements();
    List<Enticement> all = _enticementFactory.getEnticements(localizations, appConfiguration.proxyUniverse);
    return dismissed.map((dismissed) => _filterActiveEnticements(all, dismissed));
  }

  Future<void> dismissEnticement(Enticement enticement) {
    return _dismissedEnticementStore.saveEnticement(DismissedEnticementEntity.fromEnticement(enticement));
  }

  Future<void> dismissEnticementById({
    @required String proxyUniverse,
    @required String enticementId,
  }) {
    return _dismissedEnticementStore.saveEnticement(DismissedEnticementEntity(
      id: enticementId,
      proxyUniverse: proxyUniverse,
    ));
  }

  List<Enticement> _filterActiveEnticements(List<Enticement> all, List<DismissedEnticementEntity> dismissed) {
    return all.skipWhile((e) => dismissed.any((d) => d.id == e.id && d.proxyUniverse == e.proxyUniverse)).toList();
  }
}
