import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/model/payment_event_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_input_dialog.dart';
import 'package:proxy_flutter/db/event_repo.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyRepo proxyKeyRepo;
  final EventBloc eventBloc;
  final EventRepo eventRepo;
  final CryptographyService cryptographyService;

  PaymentService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyKeyRepo,
    @required this.eventBloc,
    @required this.eventRepo,
    @required this.cryptographyService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client {
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  String randomSecret([int length = 8]) {
    var rand = Random.secure();
    var codeUnits = new List.generate(
      length,
      (index) => rand.nextInt(26) + 65,
    );

    return new String.fromCharCodes(codeUnits);
  }

  Future<Uri> createPaymentAuthorization(
    ProxyLocalizations localizations,
    ProxyAccountEntity proxyAccount,
    PaymentAuthorizationInput input,
  ) async {
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(ownerProxyId);
    String paymentId = uuidFactory.v4();
    String proxyUniverse = proxyAccount.proxyUniverse;
    String ivPrefixedSecretHash =
        await cryptographyService.getHash(hashAlgorithm: 'SHA-256', input: '$paymentId#${input.secret}');
    PaymentAuthorization request = PaymentAuthorization(
        paymentId: paymentId,
        proxyAccount: proxyAccount.signedProxyAccount,
        amount: Amount(input.currency, input.amount),
        payee: Payee(
          payeeType: input.payeeType,
          proxyId: input.payeeProxyId,
          email: input.customerEmail,
          phone: input.customerPhone,
          ivPrefixedSecretHash: ivPrefixedSecretHash,
        ));
    SignedMessage<PaymentAuthorization> signedRequest = await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    Uri paymentLink = await ServiceFactory.deepLinkService().createDeepLink(
      Uri.parse('${UrlConfig.PROXY_BANKING}/actions/accept-payment?proxyUniverse=$proxyUniverse&paymentId=$paymentId'),
      title: localizations.sharePaymentTitle,
      description: localizations.sharePaymentDescription,
    );
    PaymentEventEntity event = await _createEvent(
      proxyAccount,
      request,
      signedPaymentAuthorizationRequestJson: signedRequestJson,
      paymentLink: paymentLink.toString(),
    );

    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<PaymentAuthorizationRegistered> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorizationRegistered.fromJson);
    event = await _updatePayment(event, status: signedResponse.message.paymentStatus);
    return paymentLink;
  }

  Future<void> processPaymentUpdate(PaymentUpdatedAlert alert) async {
    PaymentEventEntity event = await eventRepo.fetchEvent(alert.proxyUniverse, EventType.Payment, alert.paymentId);
    if (event == null) {
      print("No Payment Event found with id ${alert.proxyUniverse}:${alert.paymentId}");
      return null;
    }
    return refreshPaymentAuthorizationStatus(event);
  }

  Future<void> refreshPaymentAuthorizationStatus(PaymentEventEntity event) async {
    print('Refreshing $event');

    ProxyKey proxyKey = await proxyKeyRepo.fetchProxy(event.payerProxyId);
    PaymentAuthorizationStatusRequest request = PaymentAuthorizationStatusRequest(
      requestId: uuidFactory.v4(),
      paymentAuthorization: event.signedPaymentAuthorization,
    );
    SignedMessage<PaymentAuthorizationStatusRequest> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());

    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<PaymentAuthorizationStatusResponse> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorizationStatusResponse.fromJson);
    await _updatePayment(event, status: signedResponse.message.paymentStatus);
  }

  Future<PaymentEventEntity> _createEvent(
    ProxyAccountEntity proxyAccount,
    PaymentAuthorization request, {
    @required String signedPaymentAuthorizationRequestJson,
    @required String paymentLink,
  }) async {
    PaymentEventEntity event = PaymentEventEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      eventId: request.paymentId,
      status: PaymentStatusEnum.Registered,
      amount: request.amount,
      payerAccountId: proxyAccount.accountId,
      payerProxyId: proxyAccount.ownerProxyId,
      paymentLink: paymentLink,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      completed: false,
      inward: false,
      signedPaymentAuthorizationRequestJson: signedPaymentAuthorizationRequestJson,
    );
    await eventBloc.saveEvent(event);
    return event;
  }

  Future<PaymentEventEntity> _updatePayment(
    PaymentEventEntity entity, {
    PaymentStatusEnum status,
  }) async {
    // print("Setting ${entity.eventId} status to $localStatus");
    PaymentEventEntity clone = entity.copy(
      status: status ?? entity.status,
      lastUpdatedTime: DateTime.now(),
    );
    await eventBloc.saveEvent(clone);
    return clone;
  }
}
