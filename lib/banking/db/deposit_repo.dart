import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/deposit_entity.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class DepositRepo {
  final DB db;

  DepositRepo._instance(this.db);

  factory DepositRepo.instance(DB database) => DepositRepo._instance(database);

  Future<DepositEntity> fetchDeposit({
    @required String proxyUniverse,
    @required String depositId,
  }) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: allColumns,
      where: '$DEPOSIT_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [depositId, proxyUniverse],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _rowToDeposit(rows.first);
  }

  Future<int> _insert(DepositEntity deposit) {
    return db.insert(TABLE, _depositToRow(deposit));
  }

  Future<int> _update(DepositEntity deposit) {
    return db.update(
      TABLE,
      _depositToRow(deposit),
      where: '$ID = ?',
      whereArgs: [deposit.id],
    );
  }

  Future<DepositEntity> saveDeposit(DepositEntity deposit) async {
    if (deposit.id == null || deposit.id == 0) {
      int id = await _insert(deposit);
      return deposit.copy(id: id);
    } else {
      await _update(deposit);
      return deposit;
    }
  }

  static Map<String, dynamic> _depositToRow(DepositEntity deposit) => {
        PROXY_UNIVERSE: deposit.proxyUniverse,
        DEPOSIT_ID: deposit.depositId,
        COMPLETED: ConversionUtils.boolToInt(deposit.completed),
        CREATION_TIME: ConversionUtils.dateTimeToInt(deposit.creationTime),
        LAST_UPDATED_TIME:
            ConversionUtils.dateTimeToInt(deposit.lastUpdatedTime),
        STATUS: DepositEntity.depositStatusToString(deposit.status),
        AMOUNT_CURRENCY: deposit.amount.currency,
        AMOUNT_VALUE: deposit.amount.value,
        DESTINATION_PROXY_ACCOUNT_ID:
            deposit.destinationProxyAccountId.accountId,
        DESTINATION_PROXY_ACCOUNT_BANK_ID:
            deposit.destinationProxyAccountId.bankId,
        DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_ID:
            deposit.destinationProxyAccountOwnerProxyId.id,
        DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_SHA:
            deposit.destinationProxyAccountOwnerProxyId.sha256Thumbprint,
        DEPOSIT_LINK: deposit.depositLink,
        SIGNED_DEPOSIT_REQUEST: deposit.signedDepositRequestJson,
      };

  static DepositEntity _rowToDeposit(Map<dynamic, dynamic> row) =>
      DepositEntity(
        id: row[ID],
        proxyUniverse: row[PROXY_UNIVERSE],
        depositId: row[DEPOSIT_ID],
        status: DepositEntity.stringToDepositStatus(row[STATUS]),
        creationTime: ConversionUtils.intToDateTime(row[CREATION_TIME]),
        lastUpdatedTime: ConversionUtils.intToDateTime(row[LAST_UPDATED_TIME]),
        amount: Amount(row[AMOUNT_CURRENCY], row[AMOUNT_VALUE]),
        destinationProxyAccountId: ProxyAccountId(
          accountId: row[DESTINATION_PROXY_ACCOUNT_ID],
          bankId: row[DESTINATION_PROXY_ACCOUNT_BANK_ID],
          proxyUniverse: row[PROXY_UNIVERSE],
        ),
        destinationProxyAccountOwnerProxyId: ProxyId(
          row[DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_ID],
          row[DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_SHA],
        ),
        signedDepositRequestJson: row[SIGNED_DEPOSIT_REQUEST],
        depositLink: row[DEPOSIT_LINK],
        completed: ConversionUtils.intToBool(row[COMPLETED]),
      );

  static const String TABLE = "DEPOSIT";

  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ID = "id";
  static const String DEPOSIT_ID = "depositId";
  static const String STATUS = "status";
  static const String COMPLETED = "completed";
  static const String CREATION_TIME = "creationTime";
  static const String LAST_UPDATED_TIME = "lastUpdatedTime";

  static const String AMOUNT_VALUE = "amountValue";
  static const String AMOUNT_CURRENCY = "amountCurrency";

  static const String DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_ID = "ownerProxyId";
  static const String DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_SHA =
      "ownerProxySha";

  static const String DESTINATION_PROXY_ACCOUNT_ID = "proxyAccountId";
  static const String DESTINATION_PROXY_ACCOUNT_BANK_ID = "proxyAccountBankId";

  static const String SIGNED_DEPOSIT_REQUEST = "signedDepositRequest";

  static const String DEPOSIT_LINK = "depositLink";

  static const Set<String> TEXT_COLUMNS = {
    PROXY_UNIVERSE,
    DEPOSIT_ID,
    STATUS,
    AMOUNT_CURRENCY,
    DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_ID,
    DESTINATION_PROXY_ACCOUNT_OWNER_PROXY_SHA,
    DESTINATION_PROXY_ACCOUNT_ID,
    DESTINATION_PROXY_ACCOUNT_BANK_ID,
    DEPOSIT_LINK,
    SIGNED_DEPOSIT_REQUEST,
  };

  static const Set<String> INTEGER_COLUMNS = {
    ID,
    COMPLETED,
    CREATION_TIME,
    LAST_UPDATED_TIME,
  };

  static const Set<String> REAL_COLUMNS = {
    AMOUNT_VALUE,
  };

  static List<String> allColumns = [
    ...INTEGER_COLUMNS,
    ...TEXT_COLUMNS,
    ...REAL_COLUMNS,
  ];

  static Future<void> onCreate(DB db, int version) async {
    db.createTable(
      table: TABLE,
      primaryKey: ID,
      textColumns: TEXT_COLUMNS,
      integerColumns: INTEGER_COLUMNS,
      realColumns: REAL_COLUMNS,
    );
    db.addIndex(
      table: TABLE,
      columns: [DEPOSIT_ID, PROXY_UNIVERSE],
      name: 'UK_DEPOSITID_UNIVERSE',
      unique: true,
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 3:
        onCreate(db, newVersion);
        break;
    }
  }
}
