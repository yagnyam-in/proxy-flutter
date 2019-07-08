import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/payment_authorization_store.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_payee_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/payment_authorization_input_dialog.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/services/service_helper.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentAuthorizationService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils, RandomUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
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
    final encryptionService = SymmetricKeyEncryptionService();

    return PaymentAuthorizationPayeeEntity(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
      paymentEncashmentId: paymentEncashmentId,
      payeeType: input.payeeType,
      email: input.customerEmail,
      emailHash: await _computeHash(input.customerEmail),
      phone: input.customerPhone,
      phoneHash: await _computeHash(input.customerPhone),
      secretEncrypted: await encryptionService.encrypt(
        key: appConfiguration.passPhrase,
        encryptionAlgorithm: SymmetricKeyEncryptionService.ENCRYPTION_ALGORITHM,
        plainText: input.secret,
      ),
      secretHash: await _computeHash(input.secret),
    );
  }

  Future<HashValue> _computeHash(String input) {
    if (input == null) {
      return Future.value(null);
    }
    return cryptographyService.getHash(
      input: input,
      hashAlgorithm: 'SHA256',
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
    final signedPaymentAuthorization = await signMessage(request: request);
    Uri paymentLink = await ServiceFactory.deepLinkService().createDeepLink(
      Uri.parse(
          '${UrlConfig.PROXY_BANKING}/actions/accept-payment?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId'),
      title: localizations.sharePaymentTitle,
      description: localizations.sharePaymentDescription,
    );

    PaymentAuthorizationEntity paymentAuthorizationEntity = _createAuthorizationEntity(
      proxyAccount: proxyAccount,
      signedPaymentAuthorization: signedPaymentAuthorization,
      paymentLink: paymentLink.toString(),
      payees: payeeEntityList,
    );
    PaymentAuthorizationStatusEnum status = paymentAuthorizationEntity.status;

    try {
      final signedResponse = await sendAndReceive(
        url: proxyBankingUrl,
        signedRequest: signedPaymentAuthorization,
        responseParser: PaymentAuthorizationRegistered.signedMessageFromJson,
      );
      status = signedResponse.message.paymentAuthorizationStatus;
    } catch (e) {
      print("Error while registering Payment Authorization: $e");
    }

    await _paymentAuthorizationStore.savePaymentAuthorization(paymentAuthorizationEntity.copy(status: status));
    return paymentLink;
  }

  Future<void> _refreshPaymentAuthorizationStatus(
    PaymentAuthorizationEntity authorizationEntity,
  ) async {
    print('Refreshing $authorizationEntity');

    PaymentAuthorizationStatusRequest request = PaymentAuthorizationStatusRequest(
      requestId: uuidFactory.v4(),
      paymentAuthorization: authorizationEntity.signedPaymentAuthorization,
    );
    final signedRequest = await signMessage(request: request);

    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: PaymentAuthorizationStatusResponse.signedMessageFromJson,
    );
    await _savePaymentAuthorizationStatus(
      authorizationEntity,
      signedResponse.message.paymentAuthorizationStatus,
    );
  }

  Future<void> processPaymentAuthorizationUpdate(PaymentAuthorizationUpdatedAlert alert) {
    return refreshPaymentAuthorizationStatus(
      proxyUniverse: alert.proxyUniverse,
      paymentAuthorizationId: alert.paymentAuthorizationId,
    );
  }

  PaymentAuthorizationEntity _createAuthorizationEntity({
    @required ProxyAccountEntity proxyAccount,
    @required List<PaymentAuthorizationPayeeEntity> payees,
    @required SignedMessage<PaymentAuthorization> signedPaymentAuthorization,
    @required String paymentLink,
  }) {
    PaymentAuthorization paymentAuthorization = signedPaymentAuthorization.message;

    return PaymentAuthorizationEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      paymentAuthorizationId: paymentAuthorization.paymentAuthorizationId,
      status: PaymentAuthorizationStatusEnum.Created,
      amount: paymentAuthorization.amount,
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

  Future<PaymentAuthorizationEntity> _savePaymentAuthorizationStatus(
    PaymentAuthorizationEntity entity,
    PaymentAuthorizationStatusEnum status,
  ) async {
    // print("Setting ${entity.paymentAuthorizationEntityId} status to $localStatus");
    if (status == null || status == entity.status) {
      return entity;
    }
    PaymentAuthorizationEntity clone = entity.copy(
      status: status ?? entity.status,
      lastUpdatedTime: DateTime.now(),
    );
    await _paymentAuthorizationStore.savePaymentAuthorization(clone);
    return clone;
  }

  Future<SignedMessage<PaymentAuthorization>> fetchPaymentAuthorization({
    @required String proxyUniverse,
    @required String paymentAuthorizationId,
  }) async {
    String jsonResponse = await get(httpClientFactory(),
        "${UrlConfig.PROXY_BANKING}/payment-authorization?proxyUniverse=$proxyUniverse&paymentAuthorizationId=$paymentAuthorizationId");
    return messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorization.fromJson);
  }

  Future<void> refreshPaymentAuthorizationStatus({
    String proxyUniverse,
    String paymentAuthorizationId,
  }) async {
    PaymentAuthorizationEntity paymentAuthorizationEntity = await _paymentAuthorizationStore.fetchPaymentAuthorization(
      proxyUniverse: proxyUniverse,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentAuthorizationEntity != null) {
      await _refreshPaymentAuthorizationStatus(paymentAuthorizationEntity);
    }
  }
}
