import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:promo/banking/model/banking_service_provider_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:proxy_core/core.dart';

import 'abstract_store.dart';

class BankStore extends AbstractStore<BankingServiceProviderEntity> {
  BankStore(AppConfiguration appConfiguration) : super(appConfiguration);

  @override
  FromJson<BankingServiceProviderEntity> get fromJson => BankingServiceProviderEntity.fromJson;

  @override
  CollectionReference get rootCollection {
    return Firestore.instance.collection('banks');
  }

  Future<BankingServiceProviderEntity> fetchBank({ProxyId bankProxyId, String bankId}) async {
    var query;
    if (bankProxyId != null) {
      query = rootCollection
          .where(BankingServiceProviderEntity.BANK_ID, isEqualTo: bankProxyId.id)
          .where(BankingServiceProviderEntity.BANK_SHA256_THUMBPRINT, isEqualTo: bankProxyId.sha256Thumbprint);
    } else if (bankId != null) {
      query = rootCollection.where(BankingServiceProviderEntity.BANK_ID, isEqualTo: bankId);
    } else {
      throw ArgumentError("Either bankId or bankProxyId must be specified");
    }
    return firstResult(await query.getDocuments(), query);
  }
}
