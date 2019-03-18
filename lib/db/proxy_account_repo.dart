import 'dart:async';
import 'dart:convert';

import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_messages/banking.dart';
import 'package:sqflite/sqflite.dart';

class ProxyAccountRepo {
  final DB db;

  ProxyAccountRepo(this.db);

  factory ProxyAccountRepo.instance(DB database) {
    return ProxyAccountRepo(database);
  }

  Future<ProxyAccountEntity> fetchAccount(ProxyAccountId accountId) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ACCOUNT_ID, ACCOUNT_NAME, BANK_ID, BANK_NAME, CURRENCY, BALANCE, SIGNED_PROXY_ACCOUNT],
      where: '$ACCOUNT_ID = ? AND $BANK_ID = ?',
      whereArgs: [accountId.accountId, accountId.bankId],
    );
    if (rows.isNotEmpty) {
      return _rowToProxyAccountEntity(rows.first);
    }
    return Future.error("No Such Account $accountId");
  }

  Future<List<ProxyAccountEntity>> fetchAccounts() async {
    List<Map> rows = await db.query(
      TABLE,
      columns: [ACCOUNT_ID, ACCOUNT_NAME, BANK_ID, BANK_NAME, CURRENCY, BALANCE, SIGNED_PROXY_ACCOUNT],
    );
    return rows.map((e) => _rowToProxyAccountEntity(e));
  }

  ProxyAccountEntity _rowToProxyAccountEntity(Map<String, dynamic> row) {
    return ProxyAccountEntity(
      accountId: row[ACCOUNT_ID],
      accountName: row[ACCOUNT_NAME],
      bankId: row[BANK_ID],
      bankName: row[BANK_NAME],
      currency: row[CURRENCY],
      balance: row[BALANCE],
      signedProxyAccount: row[SIGNED_PROXY_ACCOUNT],
    );
  }

  static Future<int> insert(Transaction transaction, ProxyAccount proxyAccount) {
    return transaction.insert(TABLE, {
      ACCOUNT_ID: proxyAccount.proxyAccountId.accountId,
      BANK_ID: proxyAccount.proxyAccountId.bankId,
      SIGNED_PROXY_ACCOUNT: jsonEncode(proxyAccount.toJson()),
    });
  }

  static const String TABLE = "PROXY_ACCOUNT";
  static const String ACCOUNT_ID = "accountId";
  static const String ACCOUNT_NAME = "accountName";
  static const String BANK_ID = "bankId";
  static const String BANK_NAME = "bankName";
  static const String CURRENCY = "currency";
  static const String BALANCE = "balance";
  static const String SIGNED_PROXY_ACCOUNT = "account";

  static Future<void> onCreate(DB db, int version) {
    return db.execute('CREATE TABLE $TABLE ('
        '$ACCOUNT_ID TEXT PRIMARY KEY, $ACCOUNT_NAME TEXT, '
        '$BANK_ID TEXT, $BANK_NAME TEXT, '
        '$CURRENCY TEXT, $BALANCE DOUBLE, '
        '$SIGNED_PROXY_ACCOUNT TEXT'
        ')');
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) {
    return Future.value();
  }

}
