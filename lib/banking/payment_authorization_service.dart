import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_repo.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_input_dialog.dart';
import 'package:proxy_flutter/db/proxy_key_repo.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/proxy_account_entity.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentAuthorizationService with ProxyUtils, HttpClientUtils, DebugUtils {
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyRepo proxyKeyRepo;
  final PaymentAuthorizationRepo paymentAuthorizationRepo;
  final CryptographyService cryptographyService;

  PaymentAuthorizationService({
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.proxyKeyRepo,
    @required this.paymentAuthorizationRepo,
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

  Future<PaymentAuthorizationPayeeEntity> _inputToPayee(
    String proxyUniverse,
    String paymentAuthorizationId,
    PaymentAuthorizationPayeeInput input,
  ) async {
    String paymentEncashmentId = uuidFactory.v4();
    var hash = (String input) => _computeHash(
          proxyUniverse: proxyUniverse,
          paymentAuthorizationId: paymentAuthorizationId,
          paymentEncashmentId: paymentEncashmentId,
          input: input,
        );

    return PaymentAuthorizationPayeeEntity(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
      paymentEncashmentId: paymentEncashmentId,
      payeeType: input.payeeType,
      email: input.customerEmail,
      emailHash: await hash(input.customerEmail),
      phone: input.customerPhone,
      phoneHash: await hash(input.customerPhone),
      secret: input.secret,
      secretHash: await hash(input.secret),
    );
  }

  Future<List<PaymentAuthorizationPayeeEntity>> _inputsToPayees(
      String proxyUniverse,
      String paymentAuthorizationId,
      List<PaymentAuthorizationPayeeInput> inputs) async {
    return Future.wait(inputs
        .map((i) => _inputToPayee(proxyUniverse, paymentAuthorizationId, i))
        .toList());
  }

  Payee _payeeEntityToPayee(PaymentAuthorizationPayeeEntity payeeEntity) {
    return Payee(
      paymentEncashmentId: payeeEntity.paymentEncashmentId,
      payeeType: payeeEntity.payeeType,
      proxyId: payeeEntity.proxyId,
      emailHash: payeeEntity.emailHash,
      phoneHash: payeeEntity.phoneHash,
      secretHash: payeeEntity.secretHash,
    );
  }

  Future<Uri> createPaymentAuthorization(
    ProxyLocalizations localizations,
    ProxyAccountEntity proxyAccount,
    PaymentAuthorizationInput input,
  ) async {
    ProxyId ownerProxyId = proxyAccount.ownerProxyId;
    ProxyKey proxyKey = await proxyKeyRepo.fetchProxyKey(ownerProxyId);
    String paymentAuthorizationId = uuidFactory.v4();
    String proxyUniverse = proxyAccount.proxyUniverse;

    List<PaymentAuthorizationPayeeEntity> payeeEntityList =
        await _inputsToPayees(
            proxyUniverse, paymentAuthorizationId, input.payees);

    PaymentAuthorization request = PaymentAuthorization(
      paymentAuthorizationId: paymentAuthorizationId,
      proxyAccount: proxyAccount.signedProxyAccount,
      amount: Amount(input.currency, input.amount),
      payees: payeeEntityList.map(_payeeEntityToPayee),
    );
    SignedMessage<PaymentAuthorization> signedRequest =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedRequest.toJson());
    Uri paymentLink = await ServiceFactory.deepLinkService().createDeepLink(
      Uri.parse(
          '${UrlConfig.PROXY_BANKING}/actions/accept-payment?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId'),
      title: localizations.sharePaymentTitle,
      description: localizations.sharePaymentDescription,
    );

    PaymentAuthorizationEntity event = await _createAuthorizationEntity(
      proxyAccount: proxyAccount,
      request: request,
      signedPaymentAuthorizationRequestJson: signedRequestJson,
      paymentLink: paymentLink.toString(),
      payees: payeeEntityList,
    );

    print("Sending $signedRequestJson to $proxyBankingUrl");
    String jsonResponse = await post(
      httpClientFactory(),
      proxyBankingUrl,
      signedRequestJson,
    );
    print("Received $jsonResponse from $proxyBankingUrl");
    SignedMessage<PaymentAuthorizationRegistered> signedResponse =
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, PaymentAuthorizationRegistered.fromJson);
    event = await _updatePaymentAuthorization(event,
        status: signedResponse.message.paymentAuthorizationStatus);
    return paymentLink;
  }

  Future<void> refreshPaymentAuthorizationStatus(
    PaymentAuthorizationEntity authorizationEntity,
  ) async {
    print('Refreshing $authorizationEntity');

    ProxyKey proxyKey =
        await proxyKeyRepo.fetchProxyKey(authorizationEntity.payerProxyId);
    PaymentAuthorizationStatusRequest request =
        PaymentAuthorizationStatusRequest(
      requestId: uuidFactory.v4(),
      paymentAuthorization: authorizationEntity.signedPaymentAuthorization,
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
        await messageFactory.buildAndVerifySignedMessage(
            jsonResponse, PaymentAuthorizationStatusResponse.fromJson);
    await _updatePaymentAuthorization(
      authorizationEntity,
      status: signedResponse.message.paymentAuthorizationStatus,
    );
  }

  Future<PaymentAuthorizationEntity> _createAuthorizationEntity({
    @required ProxyAccountEntity proxyAccount,
    @required PaymentAuthorization request,
    @required List<PaymentAuthorizationPayeeEntity> payees,
    @required String signedPaymentAuthorizationRequestJson,
    @required String paymentLink,
  }) {
    PaymentAuthorizationEntity authorizationEntity = PaymentAuthorizationEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      paymentAuthorizationId: request.paymentAuthorizationId,
      status: PaymentAuthorizationStatusEnum.Registered,
      amount: request.amount,
      payerAccountId: proxyAccount.accountId,
      payerProxyId: proxyAccount.ownerProxyId,
      paymentLink: paymentLink,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      signedPaymentAuthorizationRequestJson:
          signedPaymentAuthorizationRequestJson,
      payees: payees,
    );
    return paymentAuthorizationRepo.savePaymentAuthorization(authorizationEntity);
  }

  Future<PaymentAuthorizationEntity> _updatePaymentAuthorization(
    PaymentAuthorizationEntity entity, {
    PaymentAuthorizationStatusEnum status,
  }) async {
    // print("Setting ${entity.eventId} status to $localStatus");
    PaymentAuthorizationEntity clone = entity.copy(
      status: status ?? entity.status,
      lastUpdatedTime: DateTime.now(),
    );
    // await eventBloc.saveEvent(clone);
    return clone;
  }

  Future<SignedMessage<PaymentAuthorization>> fetchPaymentAuthorization({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) async {
    String jsonResponse = await get(httpClientFactory(),
        "${UrlConfig.PROXY_BANKING}/payment?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId");
    return messageFactory.buildAndVerifySignedMessage(
        jsonResponse, PaymentAuthorization.fromJson);
  }

  Future<Payee> matchingPayee({
    @required PaymentAuthorization paymentAuthorization,
    String email,
    String phone,
    @required String secret,
  }) async {
    for (var payee in paymentAuthorization.payees) {
      bool match = await _matchesPyee(
        paymentAuthorization: paymentAuthorization,
        payee: payee,
        secret: secret,
        phone: phone,
        email: email,
      );
      if (match) {
        return payee;
      }
    }
    return null;
  }

  Future<bool> _matchesPyee({
    @required PaymentAuthorization paymentAuthorization,
    @required Payee payee,
    String email,
    String phone,
    @required String secret,
  }) async {
    var hash = (String input) => _computeHash(
          proxyUniverse: paymentAuthorization.proxyUniverse,
          paymentAuthorizationId: paymentAuthorization.paymentAuthorizationId,
          paymentEncashmentId: payee.paymentEncashmentId,
          input: input,
        );
    switch (payee.payeeType) {
      case PayeeTypeEnum.ProxyId:
        return false;
      case PayeeTypeEnum.Email:
        return payee.secretHash == await hash(secret) &&
            payee.emailHash == await hash(email);
      case PayeeTypeEnum.Phone:
        return payee.secretHash == await hash(secret) &&
            payee.phoneHash == await hash(phone);
      case PayeeTypeEnum.AnyoneWithSecret:
        return payee.secretHash == await hash(secret);
      default:
        return false;
    }
  }

  Future<String> _computeHash({
    @required String paymentAuthorizationId,
    @required String paymentEncashmentId,
    @required String proxyUniverse,
    @required String input,
  }) {
    if (input == null) {
      return Future.value(null);
    }
    return cryptographyService.getHash(
      hashAlgorithm: "SHA-256",
      input:
          "$proxyUniverse#$paymentAuthorizationId#$paymentEncashmentId#${input.toUpperCase()}",
    );
  }
}
