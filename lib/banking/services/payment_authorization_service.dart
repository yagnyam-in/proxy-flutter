import 'dart:async';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/db/payment_authorization_store.dart';
import 'package:promo/banking/model/payment_authorization_entity.dart';
import 'package:promo/banking/model/payment_authorization_payee_entity.dart';
import 'package:promo/banking/model/proxy_account_entity.dart';
import 'package:promo/banking/payment_authorization_input_dialog.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/secrets_service.dart';
import 'package:promo/services/service_factory.dart';
import 'package:promo/services/service_helper.dart';
import 'package:promo/url_config.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_core/services.dart';
import 'package:proxy_messages/authorization.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:uuid/uuid.dart';

class PaymentAuthorizationService with ProxyUtils, HttpClientUtils, ServiceHelper, DebugUtils, RandomUtils {
  static const PAYMENT_AUTHORIZATION_BANK_ID_QUERY_PARAM = 'bankId';
  static const PAYMENT_AUTHORIZATION_ID_QUERY_PARAM = 'paymentAuthorizationId';

  final AppConfiguration appConfiguration;
  final Uuid uuidFactory = Uuid();
  final String proxyBankingUrl;
  final HttpClientFactory httpClientFactory;
  final MessageFactory messageFactory;
  final MessageSigningService messageSigningService;
  final CryptographyService cryptographyService;
  final PaymentAuthorizationStore _paymentAuthorizationStore;
  final SecretsService secretsService;

  PaymentAuthorizationService(
    this.appConfiguration, {
    String proxyBankingUrl,
    HttpClientFactory httpClientFactory,
    @required this.messageFactory,
    @required this.messageSigningService,
    @required this.cryptographyService,
    @required this.secretsService,
  })  : proxyBankingUrl = proxyBankingUrl ?? "${UrlConfig.PROXY_BANKING}/api",
        httpClientFactory = httpClientFactory ?? HttpClientUtils.httpClient(),
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
      proxyId: input.payeeProxyId,
      email: input.customerEmail,
      emailHash: await _computeHash(input.customerEmail),
      phone: input.customerPhone,
      phoneHash: await _computeHash(input.customerPhone),
      secret: input.secret,
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

  Future<void> _uploadSecrets(List<PaymentAuthorizationPayeeEntity> payees) async {
    final encryptionService = SymmetricKeyEncryptionService();
    List<SecretForPhoneNumberRecipient> secretsForPhoneNumberRecipients = payees
        .where((payee) => payee.payeeType == PayeeTypeEnum.Phone)
        .map(
          (payee) => SecretForPhoneNumberRecipient(
            phoneNumber: payee.phone,
            secret: payee.secret ??
                encryptionService.decrypt(
                  key: appConfiguration.passPhrase,
                  cipherText: payee.secretEncrypted,
                ),
            secretHash: payee.secretHash,
          ),
        )
        .toList();
    List<SecretForEmailRecipient> secretsForEmailRecipients = payees
        .where((payee) => payee.payeeType == PayeeTypeEnum.Email)
        .map(
          (payee) => SecretForEmailRecipient(
            email: payee.email,
            secret: payee.secret ??
                encryptionService.decrypt(
                  key: appConfiguration.passPhrase,
                  cipherText: payee.secretEncrypted,
                ),
            secretHash: payee.secretHash,
          ),
        )
        .toList();
    if (secretsForPhoneNumberRecipients.isNotEmpty || secretsForEmailRecipients.isNotEmpty) {
      await secretsService.saveSecrets(secretsForPhoneNumberRecipients, secretsForEmailRecipients);
    }
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

  Future<PaymentAuthorizationEntity> createPaymentAuthorization(
    ProxyLocalizations localizations,
    ProxyAccountEntity proxyAccount,
    PaymentAuthorizationInput input,
  ) async {
    String paymentAuthorizationId = uuidFactory.v4();
    String proxyUniverse = proxyAccount.proxyUniverse;
    String bankId = proxyAccount.bankId;

    List<PaymentAuthorizationPayeeEntity> payeeEntityList =
        await _inputsToPayees(proxyUniverse, paymentAuthorizationId, input.payees);

    await _uploadSecrets(payeeEntityList);

    PaymentAuthorization request = PaymentAuthorization(
      paymentAuthorizationId: paymentAuthorizationId,
      proxyAccount: proxyAccount.signedProxyAccount,
      amount: Amount(
        currency: input.currency,
        value: input.amount,
      ),
      payees: payeeEntityList.map(_payeeEntityToPayee).toList(),
    );
    final signedPaymentAuthorization = await signMessage(
      signer: proxyAccount.ownerProxyId,
      request: request,
    );

    Uri paymentLink = Uri.parse("${UrlConfig.PROXY_BANKING}/payment-authorization"
        "?$PAYMENT_AUTHORIZATION_BANK_ID_QUERY_PARAM=$bankId"
        "&$PAYMENT_AUTHORIZATION_ID_QUERY_PARAM=$paymentAuthorizationId");
    Uri paymentDynamicLink = await ServiceFactory.deepLinkService().createDeepLink(
      Uri.parse("${UrlConfig.PROXY_BANKING}/actions/accept-payment"
          "?$PAYMENT_AUTHORIZATION_BANK_ID_QUERY_PARAM=$bankId"
          "&$PAYMENT_AUTHORIZATION_ID_QUERY_PARAM=$paymentAuthorizationId"),
      title: localizations.sharePaymentTitle,
      description: localizations.sharePaymentDescription,
    );

    PaymentAuthorizationEntity paymentAuthorizationEntity = _createAuthorizationEntity(
      proxyAccount: proxyAccount,
      signedPaymentAuthorization: signedPaymentAuthorization,
      paymentLink: paymentLink.toString(),
      paymentDynamicLink: paymentDynamicLink.toString(),
      payees: payeeEntityList,
    );

    try {
      final signedResponse = await sendAndReceive(
        url: proxyBankingUrl,
        signedRequest: signedPaymentAuthorization,
        responseParser: PaymentAuthorizationRegistered.fromJson,
      );
      paymentAuthorizationEntity = paymentAuthorizationEntity.copy(
        status: signedResponse.message.paymentAuthorizationStatus,
      );
    } catch (e) {
      print("Error while registering Payment Authorization: $e");
    }

    return _paymentAuthorizationStore.save(paymentAuthorizationEntity);
  }

  Future<void> _refreshPaymentAuthorization(
    PaymentAuthorizationEntity authorizationEntity,
  ) async {
    print('Refreshing $authorizationEntity');
    final paymentAuthorization = authorizationEntity.signedPaymentAuthorization;
    PaymentAuthorizationStatusRequest request = PaymentAuthorizationStatusRequest(
      requestId: uuidFactory.v4(),
      paymentAuthorization: paymentAuthorization,
    );
    final signedRequest = await signMessage(
      signer: authorizationEntity.payerProxyId,
      request: request,
    );

    final signedResponse = await sendAndReceive(
      url: proxyBankingUrl,
      signedRequest: signedRequest,
      responseParser: PaymentAuthorizationStatusResponse.fromJson,
    );
    await _savePaymentAuthorizationStatus(
      authorizationEntity,
      signedResponse.message.paymentAuthorizationStatus,
    );
  }

  PaymentAuthorizationEntity _createAuthorizationEntity({
    @required ProxyAccountEntity proxyAccount,
    @required List<PaymentAuthorizationPayeeEntity> payees,
    @required SignedMessage<PaymentAuthorization> signedPaymentAuthorization,
    @required String paymentDynamicLink,
    @required String paymentLink,
  }) {
    PaymentAuthorization paymentAuthorization = signedPaymentAuthorization.message;

    return PaymentAuthorizationEntity(
      proxyUniverse: proxyAccount.proxyUniverse,
      paymentAuthorizationId: paymentAuthorization.paymentAuthorizationId,
      status: PaymentAuthorizationStatusEnum.Created,
      amount: paymentAuthorization.amount,
      payerAccountId: proxyAccount.proxyAccountId,
      payerProxyId: proxyAccount.ownerProxyId,
      paymentAuthorizationLink: paymentLink,
      paymentAuthorizationDynamicLink: paymentDynamicLink,
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
    return _paymentAuthorizationStore.save(clone);
  }

  Future<SignedMessage<PaymentAuthorization>> fetchRemotePaymentAuthorization({
    @required String bankId,
    @required String paymentAuthorizationId,
  }) async {
    String jsonResponse = await get(httpClientFactory(),
        "${UrlConfig.PROXY_BANKING}/payment-authorization?$PAYMENT_AUTHORIZATION_BANK_ID_QUERY_PARAM=$bankId&$PAYMENT_AUTHORIZATION_ID_QUERY_PARAM=$paymentAuthorizationId");
    return messageFactory.buildAndVerifySignedMessage(jsonResponse, PaymentAuthorization.fromJson);
  }

  Future<void> processPaymentAuthorizationUpdatedAlert(PaymentAuthorizationUpdatedAlert alert) {
    return _refreshPaymentAuthorizationById(
      bankId: alert.payerAccountId.bankId,
      paymentAuthorizationId: alert.paymentAuthorizationId,
    );
  }

  Future<void> processPaymentAuthorizationUpdatedLiteAlert(PaymentAuthorizationUpdatedLiteAlert alert) {
    return _refreshPaymentAuthorizationById(
      bankId: alert.payerAccountId.bankId,
      paymentAuthorizationId: alert.paymentAuthorizationId,
    );
  }

  Future<void> _refreshPaymentAuthorizationById({
    @required String bankId,
    @required String paymentAuthorizationId,
  }) async {
    PaymentAuthorizationEntity paymentAuthorizationEntity = await _paymentAuthorizationStore.fetch(
      bankId: bankId,
      paymentAuthorizationId: paymentAuthorizationId,
    );
    if (paymentAuthorizationEntity != null) {
      await _refreshPaymentAuthorization(paymentAuthorizationEntity);
    }
  }

  Future<void> refreshPaymentAuthorizationByInternalId(String internalId) async {
    final paymentAuthorizationEntity = await _paymentAuthorizationStore.fetchByInternalId(internalId);
    if (paymentAuthorizationEntity != null) {
      await _refreshPaymentAuthorization(paymentAuthorizationEntity);
    }
  }
}
