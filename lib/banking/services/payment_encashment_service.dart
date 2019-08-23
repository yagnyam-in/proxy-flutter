import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_flutter/banking/db/payment_encashment_store.dart';
import 'package:proxy_flutter/banking/model/payment_encashment_entity.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/services/service_helper.dart';
import 'package:proxy_flutter/url_config.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentEncashmentService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils, RandomUtils {
  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final CryptographyService cryptographyService;
  final PaymentEncashmentStore _paymentEncashmentStore;

  PaymentEncashmentService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.cryptographyService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? ProxyHttpClient.client,
        _paymentEncashmentStore = PaymentEncashmentStore(appConfiguration) {
    assert(appConfiguration != null);
    assert(isNotEmpty(this.proxyBankingUrl));
  }

  Future<Payee> matchingPayee({
    @required PaymentAuthorization paymentAuthorization,
    String email,
    String phone,
    @required String secret,
  }) async {
    for (var payee in paymentAuthorization.payees) {
      bool match = await _matchesPayee(
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

  Future<bool> _matchesPayee({
    @required PaymentAuthorization paymentAuthorization,
    @required Payee payee,
    String email,
    String phone,
    String secret,
  }) async {
    switch (payee.payeeType) {
      case PayeeTypeEnum.ProxyId:
        return false;
      case PayeeTypeEnum.Email:
        return await _verifyHash(email, payee.emailHash) && await _verifyHash(secret, payee.secretHash);
      case PayeeTypeEnum.Phone:
        return await _verifyHash(email, payee.phoneHash) && await _verifyHash(secret, payee.secretHash);
      case PayeeTypeEnum.AnyoneWithSecret:
        return await _verifyHash(secret, payee.secretHash);
      default:
        return false;
    }
  }

  Future<bool> _verifyHash(String input, HashValue hash) async {
    if (input == null) {
      return false;
    }
    return cryptographyService.verifyHash(hashValue: hash, input: input);
  }

  Future<PaymentEncashmentEntity> acceptPayment({
    @required SignedMessage<PaymentAuthorization> signedPaymentAuthorization,
    @required Payee payee,
    String paymentLink,
    String email,
    String phone,
    String secret,
  }) async {
    PaymentAuthorization paymentAuthorization = signedPaymentAuthorization.message;
    var proxyAccount = await BankingServiceFactory.bankingService(appConfiguration).fetchOrCreateProxyWallet(
      ownerProxyId: appConfiguration.masterProxyId,
      proxyUniverse: paymentAuthorization.proxyUniverse,
      currency: paymentAuthorization.currency,
    );

    PaymentEncashment encashment = PaymentEncashment(
      paymentEncashmentId: payee.paymentEncashmentId,
      paymentAuthorization: signedPaymentAuthorization,
      payeeAccount: proxyAccount.signedProxyAccount,
      secret: secret,
    );
    final signedEncashment = await signMessage(request: encashment);

    PaymentEncashmentEntity encashmentEntity = await _createPaymentEncashmentEntity(
      payeeAccount: proxyAccount,
      signedPaymentEncashment: signedEncashment,
      paymentLink: paymentLink,
    );
    PaymentEncashmentStatusEnum status = encashmentEntity.status;

    try {
      final signedResponse = await sendAndReceive(
        url: proxyBankingUrl,
        signedRequest: signedEncashment,
        responseParser: PaymentEncashmentRegistered.fromJson,
      );
      status = signedResponse.message.paymentEncashmentStatus;
    } finally {
      await _paymentEncashmentStore.savePaymentEncashment(encashmentEntity.copy(status: status));
    }
    return encashmentEntity;
  }

  Future<PaymentEncashmentEntity> _createPaymentEncashmentEntity({
    @required ProxyAccountEntity payeeAccount,
    @required SignedMessage<PaymentEncashment> signedPaymentEncashment,
    @required String paymentLink,
    String email,
    String phone,
  }) async {
    PaymentEncashment paymentEncashment = signedPaymentEncashment.message;
    final encryptionService = SymmetricKeyEncryptionService();

    return PaymentEncashmentEntity(
      proxyUniverse: payeeAccount.proxyUniverse,
      paymentEncashmentId: paymentEncashment.paymentEncashmentId,
      paymentAuthorizationId: paymentEncashment.paymentAuthorizationId,
      status: PaymentEncashmentStatusEnum.Created,
      amount: paymentEncashment.amount,
      payeeAccountId: payeeAccount.accountId,
      payeeProxyId: payeeAccount.ownerProxyId,
      paymentAuthorizationLink: paymentLink,
      signedPaymentEncashment: signedPaymentEncashment,
      creationTime: DateTime.now(),
      lastUpdatedTime: DateTime.now(),
      phone: phone,
      email: email,
      secretEncrypted: await encryptionService.encrypt(
        key: appConfiguration.passPhrase,
        encryptionAlgorithm: SymmetricKeyEncryptionService.ENCRYPTION_ALGORITHM,
        plainText: paymentEncashment.secret,
      ),
      completed: false,
    );
  }

  Future<PaymentEncashmentEntity> _savePaymentEncashmentStatus(
    PaymentEncashmentEntity entity,
    PaymentEncashmentStatusEnum status,
  ) async {
    if (status == null || status == entity.status) {
      return entity;
    }

    PaymentEncashmentEntity clone = entity.copy(
      status: status ?? entity.status,
      lastUpdatedTime: DateTime.now(),
    );
    await _paymentEncashmentStore.savePaymentEncashment(clone);
    return clone;
  }

  Future<void> _refreshPaymentEncashmentStatus(
    PaymentEncashmentEntity encashmentEntity,
  ) async {
    print('Refreshing $encashmentEntity');
    PaymentEncashmentStatusRequest statusRequest = PaymentEncashmentStatusRequest(
      requestId: uuidFactory.v4(),
      paymentEncashment: encashmentEntity.signedPaymentEncashment,
    );
    final signedRequest = await signMessage(request: statusRequest);
    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: PaymentEncashmentStatusResponse.fromJson,
    );
    await _savePaymentEncashmentStatus(
      encashmentEntity,
      signedResponse.message.paymentEncashmentStatus,
    );
  }

  Future<void> refreshPaymentEncashmentStatus({
    String proxyUniverse,
    String paymentAuthorizationId,
    String paymentEncashmentId,
  }) async {
    PaymentEncashmentEntity paymentEncashmentEntity = await _paymentEncashmentStore.fetchPaymentEncashment(
      proxyUniverse: proxyUniverse,
      paymentEncashmentId: paymentEncashmentId,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentEncashmentEntity != null) {
      await _refreshPaymentEncashmentStatus(paymentEncashmentEntity);
    }
  }

  Future<void> processPaymentEncashmentUpdatedAlert(PaymentEncashmentUpdatedAlert alert) {
    return refreshPaymentEncashmentStatus(
      proxyUniverse: alert.proxyUniverse,
      paymentEncashmentId: alert.paymentEncashmentId,
      paymentAuthorizationId: alert.paymentAuthorizationId,
    );
  }

  Future<void> processPaymentEncashmentUpdatedLiteAlert(PaymentEncashmentUpdatedLiteAlert alert) {
    return refreshPaymentEncashmentStatus(
      proxyUniverse: alert.proxyUniverse,
      paymentEncashmentId: alert.paymentEncashmentId,
      paymentAuthorizationId: alert.paymentAuthorizationId,
    );
  }
}
