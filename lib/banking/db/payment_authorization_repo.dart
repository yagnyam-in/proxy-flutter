import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_payee_repo.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

class PaymentAuthorizationRepo {
  final DB db;
  final PaymentAuthorizationPayeeRepo payeeRepo;

  PaymentAuthorizationRepo._instance(this.db, this.payeeRepo);

  factory PaymentAuthorizationRepo.instance(DB database) =>
      PaymentAuthorizationRepo._instance(
          database, PaymentAuthorizationPayeeRepo.instance(database));

  Future<PaymentAuthorizationEntity> fetchPaymentAuthorization({
    @required String proxyUniverse,
    @required String authorizationId,
  }) async {
    List<PaymentAuthorizationPayeeEntity> payees =
        await payeeRepo.fetchPaymentAuthorizationPayee(
      proxyUniverse: proxyUniverse,
      authorizationId: authorizationId,
    );
    List<Map> rows = await db.query(
      TABLE,
      columns: authorizationAllColumns,
      where: '$PAYMENT_AUTHORIZATION_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [authorizationId, proxyUniverse],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _rowToPaymentAuthorization(rows.first, payees);
  }

  Future<int> _insert(PaymentAuthorizationEntity deposit) {
    return db.insert(TABLE, _paymentAuthorizationToRow(deposit));
  }

  Future<int> _update(PaymentAuthorizationEntity deposit) {
    return db.update(
      TABLE,
      _paymentAuthorizationToRow(deposit),
      where: '$ID = ?',
      whereArgs: [deposit.id],
    );
  }

  Future<PaymentAuthorizationEntity> savePaymentAuthorization(
      PaymentAuthorizationEntity deposit) async {
    if (deposit.id == null || deposit.id == 0) {
      int id = await _insert(deposit);
      return deposit.copy(id: id);
    } else {
      await _update(deposit);
      return deposit;
    }
  }

  static PaymentAuthorizationStatusEnum _stringToAuthorizationStatus(
    String value, {
    PaymentAuthorizationStatusEnum orElse =
        PaymentAuthorizationStatusEnum.InProcess,
  }) {
    return ConversionUtils.stringToEnum(
      value,
      orElse: orElse,
      values: PaymentAuthorizationStatusEnum.values,
      enumName: "PaymentAuthorizationStatusEnum",
    );
  }

  static String _authorizationStatusToString(
    PaymentAuthorizationStatusEnum value,
  ) {
    return ConversionUtils.enumToString(
      value,
      enumName: "PaymentAuthorizationStatusEnum",
    );
  }

  Map<String, dynamic> _paymentAuthorizationToRow(
          PaymentAuthorizationEntity authorization) =>
      {
        PROXY_UNIVERSE: authorization.proxyUniverse,
        ID: authorization.id,
        CREATION_TIME:
            ConversionUtils.dateTimeToInt(authorization.creationTime),
        LAST_UPDATED_TIME:
            ConversionUtils.dateTimeToInt(authorization.lastUpdatedTime),
        STATUS: _authorizationStatusToString(authorization.status),
        AMOUNT_CURRENCY: authorization.amount.currency,
        AMOUNT_VALUE: authorization.amount.value,
        PAYER_PROXY_ACCOUNT_ID: authorization.payerAccountId.accountId,
        PAYER_PROXY_ACCOUNT_BANK_ID: authorization.payerAccountId.bankId,
        PAYER_PROXY_ID: authorization.payerProxyId.id,
        PAYER_PROXY_SHA: authorization.payerProxyId.sha256Thumbprint,
        SIGNED_PAYMENT_AUTHORIZATION_REQUEST:
            authorization.signedPaymentAuthorizationRequestJson,
        PAYMENT_LINK: authorization.paymentLink,
      };

  PaymentAuthorizationEntity _rowToPaymentAuthorization(
    Map<dynamic, dynamic> row,
    List<PaymentAuthorizationPayeeEntity> payees,
  ) =>
      PaymentAuthorizationEntity(
        id: row[ID],
        proxyUniverse: row[PROXY_UNIVERSE],
        paymentAuthorizationId: row[PAYMENT_AUTHORIZATION_ID],
        creationTime: DateTime.fromMillisecondsSinceEpoch(
                row[CREATION_TIME] as int,
                isUtc: true)
            .toLocal(),
        lastUpdatedTime: DateTime.fromMillisecondsSinceEpoch(
                row[LAST_UPDATED_TIME] as int,
                isUtc: true)
            .toLocal(),
        status: _stringToAuthorizationStatus(row[STATUS]),
        amount: Amount(
          currency: row[AMOUNT_CURRENCY],
          value: row[AMOUNT_VALUE],
        ),
        payerAccountId: ProxyAccountId(
          accountId: row[PAYER_PROXY_ACCOUNT_ID],
          bankId: row[PAYER_PROXY_ACCOUNT_BANK_ID],
          proxyUniverse: row[PROXY_UNIVERSE],
        ),
        payerProxyId: ProxyId(
          row[PAYER_PROXY_ID],
          row[PAYER_PROXY_SHA],
        ),
        signedPaymentAuthorizationRequestJson:
            row[SIGNED_PAYMENT_AUTHORIZATION_REQUEST],
        paymentLink: row[PAYMENT_LINK],
        payees: payees,
      );

  static const String PAYEE_TABLE = "PAYMENT_AUTHORIZATION_PAYEE";

  static const String ID = "id";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PAYMENT_AUTHORIZATION_ID = "paymentAuthorizationId";

  static const String STATUS = "status";
  static const String CREATION_TIME = "creationTime";
  static const String LAST_UPDATED_TIME = "lastUpdatedTime";

  static const String AMOUNT_VALUE = "amountValue";
  static const String AMOUNT_CURRENCY = "amountCurrency";

  static const String PAYER_PROXY_ID = "payerProxyId";
  static const String PAYER_PROXY_SHA = "payerProxySha";

  static const String PAYER_PROXY_ACCOUNT_ID = "payerProxyAccountId";
  static const String PAYER_PROXY_ACCOUNT_BANK_ID = "payerProxyAccountBankId";

  static const String SIGNED_PAYMENT_AUTHORIZATION_REQUEST =
      "signedPaymentAuthorizationRequest";

  static const String PAYMENT_LINK = "paymentLink";

  static const String TABLE = "PAYMENT_AUTHORIZATION";

  static const Set<String> TEXT_COLUMNS = {
    PROXY_UNIVERSE,
    PAYMENT_AUTHORIZATION_ID,
    STATUS,
    AMOUNT_CURRENCY,
    PAYER_PROXY_ID,
    PAYER_PROXY_SHA,
    PAYER_PROXY_ACCOUNT_ID,
    PAYER_PROXY_ACCOUNT_BANK_ID,
    SIGNED_PAYMENT_AUTHORIZATION_REQUEST,
    PAYMENT_LINK,
  };

  static const Set<String> INTEGER_COLUMNS = {
    ID,
    CREATION_TIME,
    LAST_UPDATED_TIME,
  };

  static const Set<String> REAL_COLUMNS = {
    AMOUNT_VALUE,
  };

  static List<String> authorizationAllColumns = [
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
      columns: [PAYMENT_AUTHORIZATION_ID, PROXY_UNIVERSE],
      name: 'UK_AUTHID_UNIVERSE',
      unique: true,
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 3:
        onCreate(db, newVersion);
    }
  }
}
