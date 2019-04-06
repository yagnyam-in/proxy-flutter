import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

enum DepositEventStatus {
  Created,
  Rejected,
  InProcess,
  Cancelled,
  Completed,
}

class DepositEventEntity extends EventEntity {
  final DepositEventStatus status;
  final Amount amount;
  final ProxyAccountId accountId;
  final ProxyId ownerId;
  final String signedDepositRequestJson;
  SignedMessage<DepositRequest> _signedDepositRequest;

  DepositEventEntity({
    int id,
    @required String proxyUniverse,
    @required DateTime creationTime,
    @required DateTime lastUpdatedTime,
    @required String eventId,
    bool completed,
    @required this.status,
    @required this.amount,
    @required this.accountId,
    @required this.ownerId,
    @required this.signedDepositRequestJson,
  }) : super(
          id: id,
          proxyUniverse: proxyUniverse,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          eventType: EventType.Deposit,
          eventId: eventId,
        );

  @override
  Map<String, dynamic> toRow() {
    Map<String, dynamic> row = super.toRow();
    row[EventEntity.STATUS] = _eventStatusToString(status);
    row[EventEntity.PRIMARY_AMOUNT_CURRENCY] = amount.currency;
    row[EventEntity.PRIMARY_AMOUNT] = amount.value;
    row[EventEntity.PAYER_PROXY_ACCOUNT_ID] = accountId.accountId;
    row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID] = accountId.bankId;
    row[EventEntity.PAYER_PROXY_ID] = ownerId.id;
    row[EventEntity.PAYER_PROXY_SHA] = ownerId.sha256Thumbprint;
    row[EventEntity.SIGNED_REQUEST] = signedDepositRequestJson;
    return row;
  }

  SignedMessage<DepositRequest> get signedDepositRequest {
    if (_signedDepositRequest == null) {
      print("Constructing from $signedDepositRequestJson");
      _signedDepositRequest = MessageBuilder.instance().buildSignedMessage(
          signedDepositRequestJson, DepositRequest.fromJson);
    }
    return _signedDepositRequest;
  }

  DepositEventEntity.fromRow(Map<dynamic, dynamic> row)
      : status = _stringToEventStatus(row[EventEntity.STATUS]),
        amount = Amount(row[EventEntity.PRIMARY_AMOUNT_CURRENCY],
            row[EventEntity.PRIMARY_AMOUNT]),
        accountId = ProxyAccountId(
            accountId: row[EventEntity.PAYER_PROXY_ACCOUNT_ID],
            bankId: row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID],
            proxyUniverse: row[EventEntity.PROXY_UNIVERSE]),
        ownerId = ProxyId(
            row[EventEntity.PAYER_PROXY_ID], row[EventEntity.PAYER_PROXY_SHA]),
        signedDepositRequestJson = row[EventEntity.SIGNED_REQUEST],
        super.fromRow(row);

  DepositEventEntity copy(
      {DepositEventStatus status, DateTime lastUpdatedTime}) {
    DepositEventStatus effectiveStatus = status ?? this.status;
    return DepositEventEntity(
      id: this.id,
      proxyUniverse: this.proxyUniverse,
      eventId: this.eventId,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
      creationTime: this.creationTime,
      completed: isCompleteStatus(effectiveStatus),
      amount: this.amount,
      accountId: this.accountId,
      ownerId: this.ownerId,
      signedDepositRequestJson: this.signedDepositRequestJson,
      status: effectiveStatus,
    );
  }

  static bool isCompleteStatus(DepositEventStatus status) {
    return status == DepositEventStatus.Completed ||
        status == DepositEventStatus.Cancelled;
  }

  static DepositEventStatus _stringToEventStatus(String value,
      {DepositEventStatus orElse = DepositEventStatus.InProcess}) {
    return DepositEventStatus.values.firstWhere(
        (e) => ConversionUtils.isEnumEqual(e, value,
            enumName: "DepositEventStatus"),
        orElse: () => orElse);
  }

  static String _eventStatusToString(DepositEventStatus eventType) {
    return eventType
        ?.toString()
        ?.replaceFirst("DepositEventStatus.", "")
        ?.toLowerCase();
  }

  static DepositEventStatus toLocalStatus(DepositStatusEnum backendStatus) {
    switch (backendStatus) {
      case DepositStatusEnum.Registered:
        return DepositEventStatus.InProcess;
      case DepositStatusEnum.Rejected:
        return DepositEventStatus.Rejected;
      case DepositStatusEnum.InProcess:
        return DepositEventStatus.InProcess;
      case DepositStatusEnum.Cancelled:
        return DepositEventStatus.Cancelled;
      case DepositStatusEnum.Completed:
        return DepositEventStatus.Completed;
      default:
        print("Unhandled Event state: $backendStatus");
        return DepositEventStatus.InProcess;
    }
  }

  String getTitle(ProxyLocalizations localizations) {
    return localizations.depositEventTitle;
  }

  String getSubTitle(ProxyLocalizations localizations) {
    return localizations.depositEventSubTitle(accountId.accountId);
  }

  String getSuffix(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }
}
