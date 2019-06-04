import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/db/db.dart';
import 'package:meta/meta.dart';

class PaymentAuthorizationPayeeRepo {
  final DB db;

  PaymentAuthorizationPayeeRepo._instance(this.db);

  factory PaymentAuthorizationPayeeRepo.instance(DB database) =>
      PaymentAuthorizationPayeeRepo._instance(database);

  Future<List<PaymentAuthorizationPayeeEntity>> fetchPaymentAuthorizationPayee({
    @required String proxyUniverse,
    @required String authorizationId,
  }) async {
    List<Map> payeeRows = await db.query(
      TABLE,
      columns: allColumns,
      where:
      '$PAYMENT_AUTHORIZATION_ID = ? AND $PROXY_UNIVERSE = ?',
      whereArgs: [
        authorizationId,
        proxyUniverse
      ],
    );
    return payeeRows.map((r) => _rowToPayee(r)).toList();
  }

  static const String TABLE = "PAYMENT_AUTHORIZATION_PAYEE";


  Map<String, dynamic> _payeeToRow(PaymentAuthorizationPayeeEntity payee) =>
      {
        ID: payee.id,
        PROXY_UNIVERSE: payee.proxyUniverse,
        PAYMENT_AUTHORIZATION_ID: payee.paymentAuthorizationId,
        PAYMENT_ENCASHMENT_ID: payee.paymentEncashmentId,
        PAYEE_PROXY_ID: payee.proxyId?.id,
        PAYEE_PROXY_SHA: payee.proxyId?.sha256Thumbprint,
        EMAIL: payee.email,
        PHONE: payee.phone,
        SECRET: payee.secret,
        EMAIL_HASH: payee.emailHash,
        PHONE_HASH: payee.phoneHash,
        SECRET_HASH: payee.secretHash,
      };

  PaymentAuthorizationPayeeEntity _rowToPayee(Map<dynamic, dynamic> row) =>
      PaymentAuthorizationPayeeEntity(
        id: row[ID],
        proxyUniverse: row[PROXY_UNIVERSE],
        paymentAuthorizationId: row[PAYMENT_AUTHORIZATION_ID],
        paymentEncashmentId: row[PAYMENT_ENCASHMENT_ID],
        proxyId: _fetchPayeeProxyId(row),
        email: row[EMAIL],
        phone: row[PHONE],
        secret: row[SECRET],
        emailHash: row[EMAIL_HASH],
        phoneHash: row[PHONE_HASH],
        secretHash: row[SECRET_HASH],
      );

  static ProxyId _fetchPayeeProxyId(Map<dynamic, dynamic> row) {
    if (row[PAYEE_PROXY_ID] != null) {
      return ProxyId(row[PAYEE_PROXY_ID], row[PAYEE_PROXY_SHA]);
    } else {
      return null;
    }
  }

  static const String ID = "id";
  static const String PROXY_UNIVERSE = "proxyUniverse";
  static const String PAYMENT_AUTHORIZATION_ID = "paymentAuthorizationId";
  static const String PAYMENT_ENCASHMENT_ID = "paymentEncashmentId";

  static const String PAYEE_PROXY_ID = "payeeProxyId";
  static const String PAYEE_PROXY_SHA = "payeeProxySha";

  static const String PHONE = "phone";
  static const String EMAIL = "email";
  static const String SECRET = "secret";

  static const String PHONE_HASH = "phoneHash";
  static const String EMAIL_HASH = "emailHash";
  static const String SECRET_HASH = "secretHash";


  static const Set<String> TEXT_COLUMNS = {
    PROXY_UNIVERSE,
    PAYMENT_AUTHORIZATION_ID,
    PAYMENT_ENCASHMENT_ID,
    EMAIL,
    PHONE,
    SECRET,
    EMAIL_HASH,
    PHONE_HASH,
    SECRET_HASH,
    PAYEE_PROXY_ID,
    PAYEE_PROXY_SHA,
  };

  static const Set<String> INTEGER_COLUMNS = {
    ID,
  };

  static List<String> allColumns = [
    ...INTEGER_COLUMNS,
    ...TEXT_COLUMNS,
  ];


  static Future<void> onCreate(DB db, int version) async {
    db.createTable(
      table: TABLE,
      primaryKey: ID,
      textColumns: TEXT_COLUMNS,
      integerColumns: INTEGER_COLUMNS,
    );
    db.addIndex(
      table: TABLE,
      columns: [PAYMENT_AUTHORIZATION_ID, PROXY_UNIVERSE],
      name: 'UK_AUTHID_UNIVERSE',
      unique: false,
    );
  }

  static Future<void> onUpgrade(DB db, int oldVersion, int newVersion) async {
    switch (oldVersion) {
      case 3:
        onCreate(db, newVersion);
    }
  }

}
