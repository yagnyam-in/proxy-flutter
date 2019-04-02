import 'dart:async';

import 'package:flutter/material.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/db/enticement_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement_entity.dart';

typedef EnticementEntity _EnticementEnricher(ProxyLocalizations localizations, EnticementEntity source);

class EnticementBloc {
  static const START = EnticementRepo.START;
  static const LOAD_MONEY = EnticementRepo.LOAD_MONEY;
  static const SETUP_BUNQ_ACCOUNT = EnticementRepo.SETUP_BUNQ_ACCOUNT;

  static final Map<String, _EnticementEnricher> enrichMethods = {
    START: start,
    LOAD_MONEY: loadMoney,
    SETUP_BUNQ_ACCOUNT: setupBunqAccount,
  };

  final EnticementRepo _enticementRepo;
  final _enticementsStreamController = StreamController<List<EnticementEntity>>.broadcast();

  EnticementBloc({@required EnticementRepo enticementRepo}) : _enticementRepo = enticementRepo {
    assert(this._enticementRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing enticements");
    _enticementRepo.fetchActiveEnticements().then(
      (r) {
        _enticementsStreamController.sink.add(r);
      },
      onError: (e) {
        print("Failed to fetch Receiving Accounts");
      },
    );
  }

  Stream<List<EnticementEntity>> getEnticements(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return _enticementsStreamController.stream
        .map((enticements) => enticements.map((e) => _enrichEnticementEntity(localizations, e)).toList());
  }

  EnticementEntity _enrichEnticementEntity(ProxyLocalizations localizations, EnticementEntity enticement) {
    return enrichMethods[enticement.enticementId](localizations, enticement);
  }

  Future<void> dismissEnticement(String enticementId) async {
    await EnticementRepo.instance(DB.instance()).dismissEnticement(enticementId);
    _refresh();
  }

  void dispose() {
    _enticementsStreamController.close();
  }

  static EnticementEntity start(ProxyLocalizations localizations, EnticementEntity source) {
    return source.copy(
      enticementId: START,
      title: localizations.startBankingTitle,
      description: localizations.startBankingDescription,
    );
  }

  static EnticementEntity loadMoney(ProxyLocalizations localizations, EnticementEntity source) {
    return source.copy(
      enticementId: LOAD_MONEY,
      title: localizations.loadMoneyTitle,
      description: localizations.loadMoneyDescription,
    );
  }

  static EnticementEntity setupBunqAccount(ProxyLocalizations localizations, EnticementEntity source) {
    return source.copy(
      enticementId: SETUP_BUNQ_ACCOUNT,
      title: localizations.addBunqAccountTitle,
      description: localizations.addBunqAccountDescription,
    );
  }
}
