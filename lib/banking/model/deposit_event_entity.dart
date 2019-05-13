import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/utils/conversion_utils.dart';
import 'package:proxy_messages/banking.dart';

enum DepositEventStatus {
  Registered,
  Created,
  Rejected,
  InProcess,
  Cancelled,
  Completed,
}

class DepositEventEntity extends EventEntity with ProxyUtils {
  static final Set<DepositEventStatus> cancellableStatuses = Set.of([
    DepositEventStatus.Created,
    DepositEventStatus.Registered,
  ]);
  static final Set<DepositEventStatus> depositPossibleStatuses = Set.of([
    DepositEventStatus.Registered,
  ]);

  final DepositEventStatus status;
  final Amount amount;
  final ProxyAccountId accountId;
  final ProxyId ownerId;
  final String signedDepositRequestJson;
  final String depositLink;
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
    this.depositLink,
    this.signedDepositRequestJson,
  }) : super(
          id: id,
          proxyUniverse: proxyUniverse,
          creationTime: creationTime,
          lastUpdatedTime: lastUpdatedTime,
          eventType: EventType.Deposit,
          eventId: eventId,
          completed: completed,
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
    row[EventEntity.DEPOSIT_LINK] = depositLink;
    row[EventEntity.SIGNED_REQUEST] = signedDepositRequestJson;
    return row;
  }

  SignedMessage<DepositRequest> get signedDepositRequest {
    if (_signedDepositRequest == null) {
      print("Constructing from $signedDepositRequestJson");
      _signedDepositRequest =
          MessageBuilder.instance().buildSignedMessage(signedDepositRequestJson, DepositRequest.fromJson);
    }
    return _signedDepositRequest;
  }

  DepositEventEntity.fromRow(Map<dynamic, dynamic> row)
      : status = _stringToEventStatus(row[EventEntity.STATUS]),
        amount = Amount(row[EventEntity.PRIMARY_AMOUNT_CURRENCY], row[EventEntity.PRIMARY_AMOUNT]),
        accountId = ProxyAccountId(
            accountId: row[EventEntity.PAYER_PROXY_ACCOUNT_ID],
            bankId: row[EventEntity.PAYER_PROXY_ACCOUNT_BANK_ID],
            proxyUniverse: row[EventEntity.PROXY_UNIVERSE]),
        ownerId = ProxyId(row[EventEntity.PAYER_PROXY_ID], row[EventEntity.PAYER_PROXY_SHA]),
        signedDepositRequestJson = row[EventEntity.SIGNED_REQUEST],
        depositLink = row[EventEntity.DEPOSIT_LINK],
        super.fromRow(row);

  DepositEventEntity copy({
    String depositLink,
    String signedDepositRequestJson,
    DepositEventStatus status,
    DateTime lastUpdatedTime,
  }) {
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
      signedDepositRequestJson: signedDepositRequestJson ?? this.signedDepositRequestJson,
      depositLink: depositLink ?? this.depositLink,
      status: effectiveStatus,
    );
  }

  static bool isCompleteStatus(DepositEventStatus status) {
    return status == DepositEventStatus.Completed || status == DepositEventStatus.Cancelled;
  }

  static DepositEventStatus _stringToEventStatus(String value,
      {DepositEventStatus orElse = DepositEventStatus.InProcess}) {
    return DepositEventStatus.values
        .firstWhere((e) => ConversionUtils.isEnumEqual(e, value, enumName: "DepositEventStatus"), orElse: () => orElse);
  }

  static String _eventStatusToString(DepositEventStatus eventType) {
    return eventType?.toString()?.replaceFirst("DepositEventStatus.", "")?.toLowerCase();
  }

  static DepositEventStatus toLocalStatus(DepositStatusEnum backendStatus) {
    switch (backendStatus) {
      case DepositStatusEnum.Registered:
        return DepositEventStatus.Registered;
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

  String getAmountText(ProxyLocalizations localizations) {
    return '${amount.value} ${Currency.currencySymbol(amount.currency)}';
  }

  String getStatus(ProxyLocalizations localizations) {
    switch (status) {
      case DepositEventStatus.Registered:
        return localizations.waitingForFunds;
      case DepositEventStatus.Created:
        return localizations.waitingForFunds;
      case DepositEventStatus.Rejected:
        return localizations.rejected;
      case DepositEventStatus.InProcess:
        return localizations.inProcess;
      case DepositEventStatus.Completed:
        return localizations.completed;
      case DepositEventStatus.Cancelled:
        return localizations.cancelled;
      default:
        print("Unhandled Event state: $status");
        return localizations.inProcess;
    }
  }

  IconData icon() {
    return Icons.file_download;
  }

  bool isCancellable() {
    return cancellableStatuses.contains(status);
  }

  bool isDepositPossible() {
    return depositPossibleStatuses.contains(status) && isNotEmpty(depositLink);
  }
}
