import 'package:flutter/material.dart';
import 'package:promo/authorizations_helper.dart';
import 'package:promo/banking/model/payment_encashment_entity.dart';
import 'package:promo/banking/payment_encashment_page.dart';
import 'package:promo/banking/services/banking_service_factory.dart';
import 'package:promo/banking/services/payment_encashment_service.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/email_authorization_store.dart';
import 'package:promo/db/phone_number_authorization_store.dart';
import 'package:promo/db/proxy_key_store.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/service_factory.dart';
import 'package:promo/utils/conversion_utils.dart';
import 'package:promo/utils/data_validations.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_messages/banking.dart';
import 'package:proxy_messages/payments.dart';
import 'package:quiver/strings.dart';

import 'proxy_account_helper.dart';

typedef OnPaymentAcceptedCallback = void Function(PaymentEncashmentEntity paymentEncashmentEntity);

class AcceptPaymentPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String bankId;
  final String paymentAuthorizationId;
  final String paymentLink;

  const AcceptPaymentPage(
    this.appConfiguration, {
    @required this.bankId,
    @required this.paymentAuthorizationId,
    this.paymentLink,
    Key key,
  }) : super(key: key);

  @override
  AcceptPaymentPageState createState() {
    return AcceptPaymentPageState(
      appConfiguration: appConfiguration,
      bankId: bankId,
      paymentAuthorizationId: paymentAuthorizationId,
    );
  }
}

class AcceptPaymentPageState extends LoadingSupportState<AcceptPaymentPage> with ProxyUtils, AccountHelper {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppConfiguration appConfiguration;
  final String bankId;
  final String paymentAuthorizationId;
  Future<SignedMessage<PaymentAuthorization>> _paymentAuthorizationMessageFuture;
  PaymentEncashmentEntity _paymentEncashmentEntity;
  bool loading = false;

  AcceptPaymentPageState({
    @required this.appConfiguration,
    @required this.bankId,
    @required this.paymentAuthorizationId,
  });

  @override
  void initState() {
    super.initState();
    _paymentAuthorizationMessageFuture = _fetchPaymentAuthorization();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (_paymentEncashmentEntity != null) {
      return PaymentEncashmentPage.forPaymentEncashment(appConfiguration, _paymentEncashmentEntity);
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.acceptPaymentPageTitle + appConfiguration.proxyUniverseSuffix),
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: futureBuilder(
            name: "Payment Authorization Fetcher",
            future: _paymentAuthorizationMessageFuture,
            emptyMessage: localizations.invalidPayment,
            builder: (context, authorization) => _AcceptPaymentPageBody(
              scaffoldKey: _scaffoldKey,
              appConfiguration: appConfiguration,
              paymentAuthorization: authorization,
              paymentLink: widget.paymentLink,
            ),
          ),
        ),
      ),
    );
  }

  Future<SignedMessage<PaymentAuthorization>> _fetchPaymentAuthorization() {
    return BankingServiceFactory.paymentAuthorizationService(appConfiguration).fetchRemotePaymentAuthorization(
      bankId: bankId,
      paymentAuthorizationId: paymentAuthorizationId,
    );
  }
}

class _AcceptPaymentPageBody extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final AppConfiguration appConfiguration;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;
  final String paymentLink;

  const _AcceptPaymentPageBody({
    Key key,
    @required this.scaffoldKey,
    @required this.appConfiguration,
    @required this.paymentAuthorization,
    @required this.paymentLink,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AcceptPaymentPageBodyState(
      appConfiguration: appConfiguration,
      paymentAuthorization: paymentAuthorization,
    );
  }
}

class _AcceptPaymentPageBodyState extends LoadingSupportState<_AcceptPaymentPageBody> with AuthorizationsHelper {
  final AppConfiguration appConfiguration;
  final PaymentEncashmentService paymentEncashmentService;
  final SignedMessage<PaymentAuthorization> paymentAuthorization;
  final TextEditingController secretController;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;
  Future<Set<String>> authorizedEmails;
  Future<Set<String>> authorizedPhoneNumbers;

  bool loading = false;
  Future<bool> _paymentCanBeAcceptedFuture;

  _AcceptPaymentPageBodyState({Key key, @required this.appConfiguration, @required this.paymentAuthorization})
      : paymentEncashmentService = BankingServiceFactory.paymentEncashmentService(appConfiguration),
        secretController = TextEditingController(),
        phoneNumberController = TextEditingController(),
        emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentCanBeAcceptedFuture = _canPaymentBeAccepted();
    authorizedEmails = EmailAuthorizationStore(appConfiguration).authorizedEmails(appConfiguration.masterProxyId);
    authorizedPhoneNumbers =
        PhoneNumberAuthorizationStore(appConfiguration).authorizedPhoneNumbers(appConfiguration.masterProxyId);
    authorizedEmails.then((emails) => _autoPopulateEmail(emails), onError: (e) {
      print("Error fetching authorized emails");
    });
    authorizedPhoneNumbers.then((phoneNumbers) => _autoPopulatePhoneNumber(phoneNumbers), onError: (e) {
      print("Error fetching authorized phone numbers");
    });
    secretController.text = _secretFromPaymentLink;
  }

  String get _secretFromPaymentLink {
    final fragment = Uri.parse(widget.paymentLink).fragment;
    if (isBlank(fragment)) {
      return null;
    }
    if (fragment.startsWith('secret=')) {
      return fragment.replaceFirst('secret=', '');
    }
    return null;
  }

  void _autoPopulatePhoneNumber(Set<String> phoneNumbers) {
    print("Got Authorized Phone Numbers $phoneNumbers");
    phoneNumbers.forEach((phone) async {
      final payee = await paymentEncashmentService.matchingPayee(
        paymentAuthorization: paymentAuthorization.message,
        phone: phone,
      );
      if (payee != null) {
        phoneNumberController.text = phone;
        String secret = await _fetchSecretForPhoneNumber(payee, phone);
        if (isNotEmpty(secret)) {
          secretController.text = secret;
          return;
        }
      }
    });
  }

  void _autoPopulateEmail(Set<String> emails) {
    print("Got Authorized Emails $emails");
    emails.forEach((email) async {
      final payee = await paymentEncashmentService.matchingPayee(
        paymentAuthorization: paymentAuthorization.message,
        email: email,
      );
      if (payee != null) {
        emailController.text = email;
        String secret = await _fetchSecretForEmail(payee, email);
        if (isNotEmpty(secret)) {
          secretController.text = secret;
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BusyChildWidget(
      loading: loading,
      child: futureBuilder(
        name: 'Can Payment Be Accepted',
        future: _paymentCanBeAcceptedFuture,
        builder: _builder,
      ),
    );
  }

  Widget _builder(BuildContext context, bool paymentCanBeAccepted) {
    var amount = paymentAuthorization.message.amount;

    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListView(
      children: <Widget>[
        const SizedBox(height: 16.0),
        Icon(Icons.file_download, size: 64.0),
        const SizedBox(height: 24.0),
        Center(
          child: Text(
            localizations.amount,
          ),
        ),
        const SizedBox(height: 8.0),
        Center(
          child: Text(
            '${amount.value} ${Currency.currencySymbol(amount.currency)}',
            style: themeData.textTheme.title,
          ),
        ),
        if (paymentCanBeAccepted) ..._acceptPaymentWidget(context) else ..._paymentCanNotBeAcceptedWidget(context)
      ],
    );
  }

  List<Widget> _acceptPaymentToPhoneWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.customerPhone,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: TextField(
            controller: phoneNumberController,
            maxLines: 1,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _validatePhoneNumber(context, removeWhiteSpaces(value)),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
    ];
  }

  List<Widget> _acceptPaymentToEmailWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.customerEmail,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: TextField(
            controller: emailController,
            maxLines: 1,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _validateEmail(context, removeWhiteSpaces(value)),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
    ];
  }

  List<Widget> _acceptPaymentBySecretWidget(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.secretPin,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: TextField(
            controller: secretController,
            maxLines: 1,
            keyboardType: TextInputType.visiblePassword,
            textAlign: TextAlign.center,
            style: themeData.textTheme.title,
          ),
        ),
      ),
      const SizedBox(height: 8.0),
    ];
  }

  List<Widget> _acceptPaymentWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      if (_hasPaymentToPhone) ..._acceptPaymentToPhoneWidget(context),
      if (_hasPaymentToEmail) ..._acceptPaymentToEmailWidget(context),
      if (_hasPaymentBySecret) ..._acceptPaymentBySecretWidget(context),
      ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: [
          RaisedButton.icon(
            onPressed: () => invoke(
              () => acceptPayment(context),
              name: 'Accept Payment',
              onError: () => showToast(localizations.somethingWentWrong),
            ),
            icon: Icon(Icons.file_download),
            label: Text(localizations.acceptPaymentButtonLabel),
          )
        ],
      ),
    ];
  }

  List<Widget> _paymentCanNotBeAcceptedWidget(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return [
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.paymentCanNotBeAccepted,
          style: TextStyle(color: Colors.red),
        ),
      ),
    ];
  }

  Future<bool> _canPaymentBeAccepted() async {
    if (_hasPaymentBySecret || _hasPaymentToEmail || _hasPaymentToPhone) {
      return true;
    }
    return _isPaymentByPayeeId();
  }

  Future<bool> _isPaymentByPayeeId() async {
    Payee payee = await _payeeByPayeeId();
    return payee != null;
  }

  Future<Payee> _payeeByPayeeId() {
    return paymentAuthorization.message.payees
        .where((payee) => payee.payeeType == PayeeTypeEnum.ProxyId)
        .map((payee) async {
          if (await ProxyKeyStore(appConfiguration).hasProxyKey(payee.proxyId)) {
            return payee;
          }
          return null;
        })
        .where((p) => p != null)
        .first;
  }

  bool get _hasPaymentBySecret {
    for (var payee in paymentAuthorization.message.payees) {
      if (payee.payeeType == PayeeTypeEnum.AnyoneWithSecret) {
        return true;
      }
    }
    return false;
  }

  bool get _hasPaymentToEmail {
    for (var payee in paymentAuthorization.message.payees) {
      if (payee.payeeType == PayeeTypeEnum.Email) {
        return true;
      }
    }
    return false;
  }

  bool get _hasPaymentToPhone {
    for (var payee in paymentAuthorization.message.payees) {
      if (payee.payeeType == PayeeTypeEnum.Phone) {
        return true;
      }
    }
    return false;
  }

  String get _secret {
    return nullIfEmpty(secretController.text);
  }

  String get _phoneNumber {
    return removeWhiteSpaces(nullIfEmpty(phoneNumberController.text));
  }

  String get _email {
    return removeWhiteSpaces(nullIfEmpty(emailController.text));
  }

  Future<void> _validatePhoneNumber(BuildContext context, String phoneNumber) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!isPhoneNumber(phoneNumber)) {
      showToast(localizations.invalidPhoneNumber);
      return;
    }
    Payee payee = await paymentEncashmentService.matchingPayee(
      paymentAuthorization: paymentAuthorization.message,
      phone: phoneNumber,
    );
    if (payee == null) {
      showToast(localizations.phoneNumberIsNotValidForThisPayment);
      return;
    }
    String secret = await _fetchSecretForPhoneNumber(payee, phoneNumber);
    if (isNotEmpty(secret)) {
      secretController.text = secret;
      return;
    }
    _showToastWithAction(
      localizations.phoneNumberNotAuthorized,
      actionLabel: localizations.verifyButtonLabel,
      action: () => verifyPhoneNumber(context, phoneNumber),
    );
  }

  Future<void> _validateEmail(BuildContext context, String email) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!isEmailAddress(email)) {
      showToast(localizations.invalidPhoneNumber);
      return;
    }
    Payee payee = await paymentEncashmentService.matchingPayee(
      paymentAuthorization: paymentAuthorization.message,
      email: email,
    );
    if (payee == null) {
      showToast(localizations.emailIsNotValidForThisPayment);
      return;
    }
    String secret = await _fetchSecretForEmail(payee, email);
    if (isNotEmpty(secret)) {
      secretController.text = secret;
      return;
    }
    _showToastWithAction(
      localizations.emailNotAuthorized,
      actionLabel: localizations.verifyButtonLabel,
      action: () => verifyEmail(context, email),
    );
  }

  Future<String> _fetchSecretForPhoneNumber(Payee payee, String phoneNumber) {
    try {
      return ServiceFactory.secretsService(appConfiguration).fetchSecretForPhoneNumber(
        phoneNumber,
        payee.secretHash,
      );
    } catch (e) {
      print("Error fetching secret for $phoneNumber: $e");
    }
    return Future.value(null);
  }

  Future<String> _fetchSecretForEmail(Payee payee, String email) async {
    try {
      return ServiceFactory.secretsService(appConfiguration).fetchSecretForEmail(
        email,
        payee.secretHash,
      );
    } catch (e) {
      print("Error fetching secret for $email: $e");
    }
    return Future.value(null);
  }

  Future<void> acceptPayment(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    final paymentEncashmentEntity = await invoke(
      () => _acceptPayment(context),
      name: 'Accept Payment',
      onError: () => showToast(localizations.somethingWentWrong),
    );
    if (paymentEncashmentEntity != null) {
      Navigator.of(context).pop(paymentEncashmentEntity);
    }
  }

  Future<PaymentEncashmentEntity> _acceptPayment(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    ProxyId payeeProxyId = appConfiguration.masterProxyId;
    if (_hasPaymentBySecret && isEmpty(_secret)) {
      showToast(localizations.invalidSecret);
      return null;
    }
    if (_hasPaymentToEmail) {
      await _validateEmail(context, _email);
    }
    if (_hasPaymentToPhone) {
      await _validatePhoneNumber(context, _phoneNumber);
    }
    Payee payee;
    if (_hasPaymentToPhone || _hasPaymentToEmail || _hasPaymentBySecret) {
      payee = await paymentEncashmentService.matchingPayeeWithSecret(
        paymentAuthorization: paymentAuthorization.message,
        secret: _secret,
        phone: _phoneNumber,
        email: _email,
      );
    } else if (await _isPaymentByPayeeId()) {
      payee = await _payeeByPayeeId();
      payeeProxyId = payee.proxyId;
    }
    if (payee == null) {
      showToast(localizations.invalidInputsForEncashment);
      return null;
    }
    return paymentEncashmentService.acceptPayment(
      payee: payee,
      payeeProxyId: payeeProxyId,
      signedPaymentAuthorization: paymentAuthorization,
      paymentLink: widget.paymentLink,
      secret: _secret,
    );
  }

  void showToast(String message) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showToastWithAction(
    String message, {
    @required String actionLabel,
    @required VoidCallback action,
  }) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: action,
        ),
      ),
    );
  }
}
