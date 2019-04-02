import 'dart:async';

import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_messages/banking.dart';
import 'package:sqflite/sqflite.dart';

class ProxyAccountRepo {
  final DB db;

  ProxyAccountRepo._internal(this.db);

  factory ProxyAccountRepo.instance(DB db) => ProxyAccountRepo._internal(db);

  Future<ProxyAccountEntity> fetchAccount(ProxyAccountId accountId) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
      where: '$ACCOUNT_ID = ? AND $BANK_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [accountId.accountId, accountId.bankId, accountId.proxyUniverse],
    );
    if (rows.isNotEmpty) {
      return _rowToProxyAccountEntity(rows.first);
    }
    return null;
  }

  Future<List<ProxyAccountEntity>> fetchAccounts() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: ALL_COLUMNS,
    );
    print("Got ${rows.length} rows");
    return rows.map((e) => _rowToProxyAccountEntity(e)).toList();
  }

  ProxyAccountEntity _rowToProxyAccountEntity(Map<String, dynamic> row) {
    return ProxyAccountEntity(
      proxyUniverse: row[PROXY_UNIVERSE],
      accountId: ProxyAccountId(accountId: row[ACCOUNT_ID], bankId: row[BANK_ID], proxyUniverse: row[PROXY_UNIVERSE]),
      accountName: row[ACCOUNT_NAME],
      bankName: row[BANK_NAME],
      balance: Amount(row[CURRENCY], row[BALANCE]),
      signedProxyAccountJson: row[SIGNED_PROXY_ACCOUNT],
      ownerProxyId: new ProxyId(row[OWNER_PROXY_ID], row[OWNER_PROXY_SHA256]),
    );
  }

  static Future<int> _saveAccountInTransaction(Transaction transaction, ProxyAccountEntity proxyAccount) async {
    ProxyAccountId accountId = proxyAccount.accountId;
    Map<String, dynamic> values = {
      PROXY_UNIVERSE: proxyAccount.proxyUniverse,
      ACCOUNT_ID: accountId.accountId,
      ACCOUNT_NAME: proxyAccount.accountName,
      BANK_ID: accountId.bankId,
      BANK_NAME: proxyAccount.bankName,
      CURRENCY: proxyAccount.balance.currency,
      BALANCE: proxyAccount.balance.value,
      OWNER_PROXY_ID: proxyAccount.ownerProxyId.id,
      OWNER_PROXY_SHA256: proxyAccount.ownerProxyId.sha256Thumbprint,
      SIGNED_PROXY_ACCOUNT: proxyAccount.signedProxyAccountJson,
    };
    int updated = await transaction.update(
      TABLE,
      values,
      where: '$ACCOUNT_ID = ? AND $BANK_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [accountId.accountId, accountId.bankId, accountId.proxyUniverse],
    );
    if (updated == 0) {
      updated = await transaction.insert(TABLE, values);
    }
    return updated;
  }

  Future<int> saveAccount(ProxyAccountEntity proxyAccount) {
    return db.transaction((transaction) => _saveAccountInTransaction(transaction, proxyAccount));
  }

  Future<int> deleteAccount(ProxyAccountEntity proxyAccount) {
    ProxyAccountId accountId = proxyAccount.accountId;
    return db.delete(
      TABLE,
      where: '$ACCOUNT_ID = ? AND $BANK_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [accountId.accountId, accountId.bankId, accountId.proxyUniverse],
    );
  }

  static const String TABLE = "PROXY_ACCOUNT";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ACCOUNT_ID = "accountId";
  static const String ACCOUNT_NAME = "accountName";
  static const String BANK_ID = "bankId";
  static const String BANK_NAME = "bankName";
  static const String CURRENCY = "currency";
  static const String BALANCE = "balance";
  static const String OWNER_PROXY_ID = "ownerProxyId";
  static const String OWNER_PROXY_SHA256 = "ownerProxySha256";

  static const String SIGNED_PROXY_ACCOUNT = "account";

  static const ALL_COLUMNS = [PROXY_UNIVERSE, ACCOUNT_ID, ACCOUNT_NAME, BANK_ID, BANK_NAME, CURRENCY, BALANCE, OWNER_PROXY_ID, OWNER_PROXY_SHA256, SIGNED_PROXY_ACCOUNT];

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ('
        '$PROXY_UNIVERSE TEXT, '
        '$ACCOUNT_ID TEXT PRIMARY KEY, $ACCOUNT_NAME TEXT, '
        '$BANK_ID TEXT, $BANK_NAME TEXT, '
        '$CURRENCY TEXT, $BALANCE DOUBLE, '
        '$OWNER_PROXY_ID TEXT, $OWNER_PROXY_SHA256 TEXT, '
        '$SIGNED_PROXY_ACCOUNT TEXT'
        ')');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }
}
