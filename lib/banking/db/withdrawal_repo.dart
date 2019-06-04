import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/withdrawal_entity.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class WithdrawalRepo {
  final DB db;

  WithdrawalRepo._instance(this.db);

  factory WithdrawalRepo.instance(DB database) =>
      WithdrawalRepo._instance(database);

  Future<WithdrawalEntity> fetchWithdrawal({
    @required String proxyUniverse,
    @required String withdrawalId,
  }) async {
    List<Map> rows = await db.query(
      TABLE,
      columns: allColumns,
      where: '$WITHDRAWAL_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [withdrawalId, proxyUniverse],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _rowToWithdrawal(rows.first);
  }

  Future<int> _insert(WithdrawalEntity withdrawal) {
    return db.insert(TABLE, _withdrawalToRow(withdrawal));
  }

  Future<int> _update(WithdrawalEntity withdrawal) {
    return db.update(
      TABLE,
      _withdrawalToRow(withdrawal),
      where: '$ID = ?',
      whereArgs: [withdrawal.id],
    );
  }

  Future<WithdrawalEntity> saveWithdrawal(WithdrawalEntity withdrawal) async {
    if (withdrawal.id == null || withdrawal.id == 0) {
      int id = await _insert(withdrawal);
      return withdrawal.copy(id: id);
    } else {
      await _update(withdrawal);
      return withdrawal;
    }
  }

  static Map<String, dynamic> _withdrawalToRow(WithdrawalEntity withdrawal) => {
        PROXY_UNIVERSE: withdrawal.proxyUniverse,
        WITHDRAWAL_ID: withdrawal.withdrawalId,
        COMPLETED: ConversionUtils.boolToInt(withdrawal.completed),
        CREATION_TIME: ConversionUtils.dateTimeToInt(withdrawal.creationTime),
        LAST_UPDATED_TIME:
            ConversionUtils.dateTimeToInt(withdrawal.lastUpdatedTime),
        STATUS: WithdrawalEntity.withdrawalStatusToString(withdrawal.status),
        AMOUNT_CURRENCY: withdrawal.amount.currency,
        AMOUNT_VALUE: withdrawal.amount.value,
        PAYER_PROXY_ACCOUNT_ID: withdrawal.payerAccountId.accountId,
        PAYER_PROXY_ACCOUNT_BANK_ID: withdrawal.payerAccountId.bankId,
        PAYER_PROXY_ID: withdrawal.payerProxyId.id,
        PAYER_PROXY_SHA: withdrawal.payerProxyId.sha256Thumbprint,
        RECEIVING_ACCOUNT_ID: withdrawal.receivingAccountId,
        DESTINATION_ACCOUNT_NUMBER: withdrawal.destinationAccountNumber,
        DESTINATION_ACCOUNT_BANK: withdrawal.destinationAccountBank,
        SIGNED_WITHDRAWAL_REQUEST: withdrawal.signedWithdrawalRequestJson,
      };

  static WithdrawalEntity _rowToWithdrawal(Map<dynamic, dynamic> row) =>
      WithdrawalEntity(
        id: row[ID],
        proxyUniverse: row[PROXY_UNIVERSE],
        withdrawalId: row[WITHDRAWAL_ID],
        status: WithdrawalEntity.stringToWithdrawalStatus(row[STATUS]),
        creationTime: ConversionUtils.intToDateTime(row[CREATION_TIME]),
        lastUpdatedTime: ConversionUtils.intToDateTime(row[LAST_UPDATED_TIME]),
        amount: Amount(row[AMOUNT_CURRENCY], row[AMOUNT_VALUE]),
        payerAccountId: ProxyAccountId(
          accountId: row[PAYER_PROXY_ACCOUNT_ID],
          bankId: row[PAYER_PROXY_ACCOUNT_BANK_ID],
          proxyUniverse: row[PROXY_UNIVERSE],
        ),
        payerProxyId: ProxyId(
          row[PAYER_PROXY_ID],
          row[PAYER_PROXY_SHA],
        ),
        receivingAccountId: row[RECEIVING_ACCOUNT_ID],
        destinationAccountNumber: row[DESTINATION_ACCOUNT_NUMBER],
        destinationAccountBank: row[DESTINATION_ACCOUNT_BANK],
        signedWithdrawalRequestJson: row[SIGNED_WITHDRAWAL_REQUEST],
        completed: ConversionUtils.intToBool(row[COMPLETED]),
      );

  static const String TABLE = "WITHDRAWAL";

  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String ID = "id";
  static const String WITHDRAWAL_ID = "withdrawalId";
  static const String STATUS = "status";
  static const String COMPLETED = "completed";
  static const String CREATION_TIME = "creationTime";
  static const String LAST_UPDATED_TIME = "lastUpdatedTime";

  static const String AMOUNT_VALUE = "amountValue";
  static const String AMOUNT_CURRENCY = "amountCurrency";

  static const String PAYER_PROXY_ID = "ownerProxyId";
  static const String PAYER_PROXY_SHA = "ownerProxySha";

  static const String PAYER_PROXY_ACCOUNT_ID = "proxyAccountId";
  static const String PAYER_PROXY_ACCOUNT_BANK_ID = "proxyAccountBankId";

  static const String RECEIVING_ACCOUNT_ID = "receivingAccountId";
  static const String DESTINATION_ACCOUNT_NUMBER = "destinationAccountNumber";
  static const String DESTINATION_ACCOUNT_BANK = "destinationAccountBank";

  static const String SIGNED_WITHDRAWAL_REQUEST = "signedWithdrawalRequest";

  static const Set<String> TEXT_COLUMNS = {
    PROXY_UNIVERSE,
    WITHDRAWAL_ID,
    STATUS,
    AMOUNT_CURRENCY,
    PAYER_PROXY_ID,
    PAYER_PROXY_SHA,
    PAYER_PROXY_ACCOUNT_ID,
    PAYER_PROXY_ACCOUNT_BANK_ID,
    RECEIVING_ACCOUNT_ID,
    DESTINATION_ACCOUNT_NUMBER,
    DESTINATION_ACCOUNT_BANK,
    SIGNED_WITHDRAWAL_REQUEST,
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
      columns: [WITHDRAWAL_ID, PROXY_UNIVERSE],
      name: 'UK_WITHDRAWALID_UNIVERSE',
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
