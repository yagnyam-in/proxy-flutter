import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/banking/deposit_request_input_dialog.dart';
import 'package:proxy_flutter/banking/model/proxy_account_entity.dart';
import 'package:proxy_flutter/banking/model/receiving_account_entity.dart';
import 'package:proxy_flutter/banking/receiving_account_dialog.dart';
import 'package:proxy_flutter/banking/receiving_accounts_page.dart';
import 'package:proxy_flutter/banking/services/banking_service.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/banking/services/deposit_service.dart';
import 'package:proxy_flutter/banking/services/payment_authorization_service.dart';
import 'package:proxy_flutter/banking/services/withdrawal_service.dart';
import 'package:proxy_flutter/banking/store/proxy_account_store.dart';
import 'package:proxy_flutter/banking/widgets/account_card.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/contacts_page.dart';
import 'package:proxy_flutter/db/user_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement.dart';
import 'package:proxy_flutter/model/user_entity.dart';
import 'package:proxy_flutter/profile_page.dart';
import 'package:proxy_flutter/services/enticement_service.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/utils/random_utils.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/enticement_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';
import 'package:proxy_messages/banking.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'events_page.dart';
import 'payment_authorization_input_dialog.dart';

final Uuid uuidFactory = Uuid();

class ProxyAccountsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  ProxyAccountsPage(this.appConfiguration, {Key key}) : super(key: key) {
    print("Constructing ProxyAccountsPage");
    assert(appConfiguration != null);
  }

  @override
  _ProxyAccountsPageState createState() {
    return _ProxyAccountsPageState(appConfiguration);
  }
}

class _ProxyAccountsPageState extends LoadingSupportState<ProxyAccountsPage>
    with ProxyUtils, EnticementHelper {
  final AppConfiguration appConfiguration;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final BankingService _bankingService;
  final PaymentAuthorizationService _paymentAuthorizationService;
  final WithdrawalService _withdrawalService;
  final DepositService _depositService;
  final EnticementService _enticementService;

  Stream<List<ProxyAccountEntity>> _proxyAccountsStream;
  Stream<List<Enticement>> _enticementsStream;

  _ProxyAccountsPageState(this.appConfiguration)
      : _bankingService =
            BankingServiceFactory.bankingService(appConfiguration),
        _depositService =
            BankingServiceFactory.depositService(appConfiguration),
        _withdrawalService =
            BankingServiceFactory.withdrawalService(appConfiguration),
        _enticementService = EnticementService(appConfiguration),
        _paymentAuthorizationService =
            BankingServiceFactory.paymentAuthorizationService(appConfiguration);

  @override
  void initState() {
    super.initState();
    _proxyAccountsStream =
        ProxyAccountStore(appConfiguration).subscribeForAccounts();
    _enticementsStream = _enticementService.subscribeForFirstEnticement();
    ServiceFactory.bootService().start();
  }

  @override
  void dispose() {
    super.dispose();
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

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(localizations.bankingTitle),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_balance),
            tooltip: localizations.receivingAccountsButtonHint,
            onPressed: () => _manageReceivingAccounts(context),
          ),
          IconButton(
            icon: Icon(Icons.event),
            tooltip: localizations.eventsPageTitle,
            onPressed: () => _launchEvents(context),
          ),
          IconButton(
            icon: Icon(Icons.contacts),
            tooltip: localizations.manageContactsPageTitle,
            onPressed: () => _launchContacts(context),
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            tooltip: localizations.profilePageTitle,
            onPressed: () => _launchProfile(context),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: ListView.builder(
          itemCount: 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return streamBuilder(
                name: "Account Loading",
                stream: _proxyAccountsStream,
                builder: (context, accounts) => _accounts(context, accounts),
              );
            } else {
              return streamBuilder(
                name: "Enticement Loading",
                stream: _enticementsStream,
                loadingWidget: SizedBox.shrink(),
                builder: (context, enticements) =>
                    _enticements(context, enticements),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _accounts(BuildContext context, List<ProxyAccountEntity> accounts) {
    print("accounts : $accounts");
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: accounts.expand((account) {
        return [
          const SizedBox(height: 8.0),
          accountCard(context, account),
        ];
      }).toList(),
    );
  }

  Widget _enticements(BuildContext context, List<Enticement> enticements) {
    print("enticements : $enticements");
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: enticements.expand((enticement) {
        return [
          const SizedBox(height: 8.0),
          enticementCard(context, enticement),
        ];
      }).toList(),
    );
  }

  Widget actionBar(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        RaisedButton.icon(
          onPressed: () => _createAccountAndDeposit(context),
          icon: Icon(Icons.file_download),
          label: Text(localizations.deposit),
        ),
        RaisedButton.icon(
          onPressed: () => createAccountAndPay(context),
          icon: Icon(Icons.file_upload),
          label: Text(localizations.payment),
        ),
      ],
    );
  }

  void _createAccountAndDeposit(BuildContext context) async {
    DepositRequestInput depositInput =
        await _acceptDepositRequestInput(context);
    if (depositInput != null) {
      showToast(ProxyLocalizations.of(context)
          .creatingAnonymousAccount(depositInput.currency));
      ProxyAccountEntity proxyAccount = await _bankingService.createProxyWallet(
        ownerProxyId: widget.appConfiguration.masterProxyId,
        proxyUniverse: depositInput.proxyUniverse,
        currency: depositInput.currency,
      );
      String depositLink =
          await _depositService.depositLink(proxyAccount, depositInput);
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  Future<Uri> createAccountAndPay(BuildContext context) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    PaymentAuthorizationInput paymentInput = await _acceptPaymentInput(context);
    if (paymentInput != null) {
      showToast(localizations.creatingAnonymousAccount(paymentInput.currency));
      ProxyAccountEntity proxyAccount = await _bankingService.createProxyWallet(
        ownerProxyId: widget.appConfiguration.masterProxyId,
        proxyUniverse: paymentInput.proxyUniverse,
        currency: paymentInput.currency,
      );
      String customerName = widget.appConfiguration.customerName;
      Uri paymentLink =
          await _paymentAuthorizationService.createPaymentAuthorization(
        localizations,
        proxyAccount,
        paymentInput,
      );
      if (paymentLink != null) {
        var message = localizations.acceptPayment(paymentLink.toString()) +
            (isNotEmpty(customerName) ? ' - $customerName' : '');
        await Share.share(message);
      }
      return paymentLink;
    }
    return null;
  }

  Widget proxyUniverseAndCurrencyDialog(BuildContext context) {
    return SimpleDialog(
      title: Text('Choose Currency'),
      children: <Widget>[
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.PRODUCTION} ${Currency.INR}'),
          onPressed: () {
            Navigator.pop(
                context, Tuple2(ProxyUniverse.PRODUCTION, Currency.INR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.PRODUCTION} ${Currency.EUR}'),
          onPressed: () {
            Navigator.pop(
                context, Tuple2(ProxyUniverse.PRODUCTION, Currency.EUR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.TEST} ${Currency.INR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.TEST, Currency.INR));
          },
        ),
        SimpleDialogOption(
          child: new Text('${ProxyUniverse.TEST} ${Currency.EUR}'),
          onPressed: () {
            Navigator.pop(context, Tuple2(ProxyUniverse.TEST, Currency.EUR));
          },
        ),
      ],
    );
  }

  Widget accountCard(BuildContext context, ProxyAccountEntity account) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: AccountCard(account: account),
      actions: <Widget>[
        new IconSlideAction(
          caption: localizations.deposit,
          color: Colors.blue,
          icon: Icons.file_download,
          onTap: () => _depositToAccount(context, account),
        ),
        new IconSlideAction(
          caption: 'Withdraw',
          color: Colors.indigo,
          icon: Icons.file_upload,
          onTap: () => _withdraw(context, account),
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.refreshButtonHint,
          color: Colors.orange,
          icon: Icons.refresh,
          onTap: () => _refresh(context, account),
        ),
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => _archiveAccount(context, account),
        ),
      ],
    );
  }

  Future<void> _depositToAccount(
      BuildContext context, ProxyAccountEntity proxyAccount) async {
    DepositRequestInput input =
        await _acceptDepositRequestInput(context, proxyAccount);
    if (input != null) {
      String depositLink = await invoke(
        () => _depositService.depositLink(proxyAccount, input),
        name: "Deposit",
      );
      if (await canLaunch(depositLink)) {
        await launch(depositLink);
      } else {
        throw 'Could not launch $depositLink';
      }
    }
  }

  Future<void> _withdraw(
      BuildContext context, ProxyAccountEntity proxyAccount) async {
    print("_withdraw from $proxyAccount");
    ReceivingAccountEntity receivingAccountEntity =
        await _chooseReceivingAccountDialog(context, proxyAccount);
    if (receivingAccountEntity != null) {
      print("Actual Withdraw");
      await invoke(
        () => _withdrawalService.withdraw(proxyAccount, receivingAccountEntity),
        name: "Withdrawal",
      );
    } else {
      print("Ignoring withdraw");
    }
  }

  Future<void> _refresh(
      BuildContext context, ProxyAccountEntity proxyAccount) async {
    print("refresh $proxyAccount");
    await _bankingService.refreshAccount(proxyAccount.accountId);
  }

  void _archiveAccount(BuildContext context, ProxyAccountEntity proxyAccount) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (proxyAccount.balance.value != 0) {
      showToast(localizations.canNotDeleteActiveAccount);
      return;
    }
    ProxyAccountStore(appConfiguration).deleteAccount(proxyAccount);
  }

  void _manageReceivingAccounts(BuildContext context) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => ReceivingAccountsPage.manage(
            appConfiguration: widget.appConfiguration),
      ),
    );
  }

  void _launchEvents(BuildContext context) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) =>
            EventsPage(appConfiguration: widget.appConfiguration),
      ),
    );
  }

  void _launchContacts(BuildContext context) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) =>
            ContactsPage.manage(appConfiguration: widget.appConfiguration),
      ),
    );
  }

  void _launchProfile(BuildContext context) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) =>
            ProfilePage(appConfiguration: widget.appConfiguration),
      ),
    );
  }

  Future<ReceivingAccountEntity> _chooseReceivingAccountDialog(
      BuildContext context, ProxyAccountEntity proxyAccount) {
    return Navigator.push(
      context,
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountsPage.choose(
              appConfiguration: widget.appConfiguration,
              proxyUniverse: proxyAccount.proxyUniverse,
              currency: proxyAccount.balance.currency,
            ),
      ),
    );
  }

  Future<DepositRequestInput> _acceptDepositRequestInput(BuildContext context,
      [ProxyAccountEntity proxyAccount]) async {
    UserStore userStore = UserStore(appConfiguration);
    UserEntity user = await userStore.fetchUser();
    DepositRequestInput depositRequestInput = proxyAccount == null
        ? DepositRequestInput.fromCustomer(user)
        : DepositRequestInput.forAccount(proxyAccount, user);
    DepositRequestInput result =
        await Navigator.of(context).push(MaterialPageRoute<DepositRequestInput>(
      builder: (context) =>
          DepositRequestInputDialog(depositRequestInput: depositRequestInput),
      fullscreenDialog: true,
    ));
    if (result != null) {
      if (user != null) {
        user = user.copy(
          name: result.customerName,
          phone: result.customerPhone,
          email: result.customerEmail,
        );
      } else {
        user = UserEntity(
          id: uuidFactory.v4(),
          name: result.customerName,
          phone: result.customerPhone,
          email: result.customerEmail,
        );
      }
      await userStore.saveUser(user);
    }
    return result;
  }

  Future<PaymentAuthorizationInput> _acceptPaymentInput(BuildContext context,
      [ProxyAccountEntity proxyAccount]) async {
    PaymentAuthorizationInput paymentAuthorizationInput =
        PaymentAuthorizationInput(
      proxyUniverse: proxyAccount?.proxyUniverse,
      currency: proxyAccount?.currency,
      payees: [
        PaymentAuthorizationPayeeInput(
          secret: RandomUtils.randomSecret(),
        ),
      ],
    );
    PaymentAuthorizationInput result = await Navigator.of(context)
        .push(MaterialPageRoute<PaymentAuthorizationInput>(
      builder: (context) => PaymentAuthorizationInputDialog(
          paymentAuthorizationInput: paymentAuthorizationInput),
      fullscreenDialog: true,
    ));
    return result;
  }

  Future<ReceivingAccountEntity> createReceivingAccount(BuildContext context) {
    return Navigator.of(context).push(
      new MaterialPageRoute<ReceivingAccountEntity>(
        builder: (context) => ReceivingAccountDialog(
              appConfiguration,
            ),
        fullscreenDialog: true,
      ),
    );
  }
}
