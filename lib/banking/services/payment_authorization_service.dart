import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_input_dialog.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/proxy_key_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentAuthorizationService with ProxyUtils, HttpClientUtils, DebugUtils, RandomUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final ProxyKeyStore _proxyKeyStore;
  final CryptographyService cryptographyService;
  final PaymentAuthorizationStore _paymentAuthorizationStore;

  PaymentAuthorizationService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.cryptographyService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _proxyKeyStore = ProxyKeyStore(appConfiguration),
        _paymentAuthorizationStore = PaymentAuthorizationStore(appConfiguration) {
    assert(appConfiguration != null);
    assert(isNotEmpty(this.proxyBankingUrl));
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
      String proxyUniverse, String paymentAuthorizationId, List<PaymentAuthorizationPayeeInput> inputs) async {
    return Future.wait(inputs.map((i) => _inputToPayee(proxyUniverse, paymentAuthorizationId, i)).toList());
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
    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(ownerProxyId);
    String paymentAuthorizationId = uuidFactory.v4();
    String proxyUniverse = proxyAccount.proxyUniverse;

    List<PaymentAuthorizationPayeeEntity> payeeEntityList =
        await _inputsToPayees(proxyUniverse, paymentAuthorizationId, input.payees);

    PaymentAuthorization request = PaymentAuthorization(
      paymentAuthorizationId: paymentAuthorizationId,
      proxyAccount: proxyAccount.signedProxyAccount,
      amount: Amount(
        currency: input.currency,
        value: input.amount,
      ),
      payees: payeeEntityList.map(_payeeEntityToPayee).toList(),
    );
    SignedMessage<PaymentAuthorization> signedPaymentAuthorization =
        await messageSigningService.signMessage(request, proxyKey);
    String signedRequestJson = jsonEncode(signedPaymentAuthorization.toJson());
    Uri paymentLink = await ServiceFactory.deepLinkService().createDeepLink(
      Uri.parse(
          '${UrlConfig.PROXY_BANKING}/actions/accept-payment?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId'),
      title: localizations.sharePaymentTitle,
      description: localizations.sharePaymentDescription,
    );

    PaymentAuthorizationEntity paymentAuthorizationEntity = _createAuthorizationEntity(
      proxyAccount: proxyAccount,
      request: request,
      signedPaymentAuthorization: signedPaymentAuthorization,
      paymentLink: paymentLink.toString(),
      payees: payeeEntityList,
    );
    PaymentAuthorizationStatusEnum status = paymentAuthorizationEntity.status;

    try {
      print("Sending $signedRequestJson to $proxyBankingUrl");
      String jsonResponse = await post(
        httpClientFactory(),
        proxyBankingUrl,
        signedRequestJson,
      );
      print("Received $jsonResponse from $proxyBankingUrl");
      SignedMessage<PaymentAuthorizationRegistered> signedResponse =
          await messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorizationRegistered.fromJson);
      status = signedResponse.message.paymentAuthorizationStatus;
    } catch (e) {
      print("Error while registering Payment Authorization: $e");
    }

    paymentAuthorizationEntity = await _savePaymentAuthorization(paymentAuthorizationEntity, status: status);
    return paymentLink;
  }

  Future<void> refreshPaymentAuthorizationStatus(
    PaymentAuthorizationEntity authorizationEntity,
  ) async {
    print('Refreshing $authorizationEntity');

    ProxyKey proxyKey = await _proxyKeyStore.fetchProxyKey(authorizationEntity.payerProxyId);
    PaymentAuthorizationStatusRequest request = PaymentAuthorizationStatusRequest(
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
        await messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorizationStatusResponse.fromJson);
    await _savePaymentAuthorization(
      authorizationEntity,
      status: signedResponse.message.paymentAuthorizationStatus,
    );
  }

  PaymentAuthorizationEntity _createAuthorizationEntity({
    @required ProxyAccountEntity proxyAccount,
    @required PaymentAuthorization request,
    @required List<PaymentAuthorizationPayeeEntity> payees,
    @required SignedMessage<PaymentAuthorization> signedPaymentAuthorization,
    @required String paymentLink,
  }) {
    return PaymentAuthorizationEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      paymentAuthorizationId: request.paymentAuthorizationId,
      status: PaymentAuthorizationStatusEnum.Created,
      amount: request.amount,
      payerAccountId: proxyAccount.accountId,
      payerProxyId: proxyAccount.ownerProxyId,
      paymentAuthorizationLink: paymentLink,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      signedPaymentAuthorization: signedPaymentAuthorization,
      completed: false,
      payees: payees,
    );
  }

  Future<PaymentAuthorizationEntity> _savePaymentAuthorization(
    PaymentAuthorizationEntity entity, {
    PaymentAuthorizationStatusEnum status,
  }) async {
    // print("Setting ${entity.paymentAuthorizationEntityId} status to $localStatus");
    PaymentAuthorizationEntity clone = entity.copy(
      status: status ?? entity.status,
      lastUpdatedTime: DateTime.now(),
    );
    _paymentAuthorizationStore.savePaymentAuthorization(entity);
    return clone;
  }

  Future<SignedMessage<PaymentAuthorization>> fetchPaymentAuthorization({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) async {
    String jsonResponse = await get(httpClientFactory(),
        "${UrlConfig.PROXY_BANKING}/payment?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId");
    return messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorization.fromJson);
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
        return payee.secretHash == await hash(secret) && payee.emailHash == await hash(email);
      case PayeeTypeEnum.Phone:
        return payee.secretHash == await hash(secret) && payee.phoneHash == await hash(phone);
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
      input: "$proxyUniverse#$paymentAuthorizationId#$paymentEncashmentId#${input.toUpperCase()}",
    );
  }
}
