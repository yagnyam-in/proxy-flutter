import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/banking/db/event_store.dart';
import 'package:proxy_flutter/banking/deposit_page.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/banking/model/payment_authorization_event.dart';
import 'package:proxy_flutter/banking/model/payment_encashment_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/banking/payment_authorization_page.dart';
import 'package:proxy_flutter/banking/payment_encashment_page.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/banking/widgets/event_card.dart';
import 'package:proxy_flutter/banking/withdrawal_page.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/services/enticement_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/enticement_helper.dart';
import 'package:uuid/uuid.dart';

import 'deposit_helper.dart';
import 'payment_helper.dart';
import 'proxy_account_helper.dart';

final Uuid uuidFactory = Uuid();

class EventsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

  EventsPage(this.appConfiguration, {Key key, @required this.changeHomePage}) : super(key: key) {
    assert(appConfiguration != null);
    print("Constructing EventsPage");
  }

  @override
  _EventsPageState createState() {
    return _EventsPageState(appConfiguration, changeHomePage);
  }
}

class _EventsPageState extends LoadingSupportState<EventsPage>
    with HomePageNavigation, EnticementHelper, DepositHelper, PaymentHelper, AccountHelper {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;
  bool loading = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EventStore _eventStore;
  Stream<List<EventEntity>> _eventStream;

  _EventsPageState(this.appConfiguration, this.changeHomePage) : _eventStore = EventStore(appConfiguration);

  @override
  void initState() {
    super.initState();
    _eventStream = _eventStore.subscribeForEvents();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: new Text(localizations.eventsPageTitle + appConfiguration.proxyUniverseSuffix),
      ),
      body: streamBuilder(
        name: "Account Loading",
        stream: _eventStream,
        builder: (context, events) => _events(context, events),
      ),
      bottomNavigationBar: navigationBar(
        context,
        HomePage.EventsPage,
        changeHomePage: changeHomePage,
        busy: loading,
      ),
    );
  }

  Widget _events(BuildContext context, List<EventEntity> events) {
    print("events : $events");
    if (events.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          enticementCard(context, EnticementFactory.noEvents, cancellable: false),
        ],
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      children: events.expand((account) {
        return [
          const SizedBox(height: 4.0),
          eventCard(context, account),
        ];
      }).toList(),
    );
  }

  Widget eventCard(BuildContext context, EventEntity event) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        child: EventCard(event: event),
        onTap: () => _launchEvent(context, event),
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.refreshButtonHint,
          color: Colors.orange,
          icon: Icons.refresh,
          onTap: () => invoke(() => _refreshEvent(context, event), name: "Refresh Event"),
        ),
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => _archiveEvent(context, event),
        ),
      ],
    );
  }

  void _launchEvent(BuildContext context, EventEntity event) {
    Widget eventPage = _eventPage(event);
    if (eventPage == null) {
      return;
    }
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => eventPage,
      ),
    );
  }

  Widget _eventPage(EventEntity event) {
    switch (event.eventType) {
      case EventType.Deposit:
        return DepositPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          depositId: (event as DepositEvent).depositId,
        );
      case EventType.Withdrawal:
        return WithdrawalPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          withdrawalId: (event as WithdrawalEvent).withdrawalId,
        );
      case EventType.PaymentAuthorization:
        return PaymentAuthorizationPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          paymentAuthorizationId: (event as PaymentAuthorizationEvent).paymentAuthorizationId,
        );
      case EventType.PaymentEncashment:
        return PaymentEncashmentPage(
          appConfiguration,
          proxyUniverse: event.proxyUniverse,
          paymentEncashmentId: (event as PaymentEncashmentEvent).paymentEncashmentId,
          paymentAuthorizationId: (event as PaymentEncashmentEvent).paymentAuthorizationId,
        );
      default:
        return null;
    }
  }

  void _archiveEvent(BuildContext context, EventEntity event) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!event.completed) {
      showToast(localizations.withdrawalNotYetComplete);
    }
    await _eventStore.deleteEvent(event);
  }

  Future<void> _refreshEvent(BuildContext context, EventEntity event) async {
    switch (event.eventType) {
      case EventType.Deposit:
        await BankingServiceFactory.depositService(widget.appConfiguration).refreshDepositStatus(
          proxyUniverse: event.proxyUniverse,
          depositId: (event as DepositEvent).depositId,
        );
        break;
      case EventType.Withdrawal:
        await BankingServiceFactory.withdrawalService(widget.appConfiguration).refreshWithdrawalStatus(
          proxyUniverse: event.proxyUniverse,
          withdrawalId: (event as WithdrawalEvent).withdrawalId,
        );
        break;
      case EventType.PaymentAuthorization:
        await BankingServiceFactory.paymentAuthorizationService(widget.appConfiguration)
            .refreshPaymentAuthorizationStatus(
          proxyUniverse: event.proxyUniverse,
          paymentAuthorizationId: (event as PaymentAuthorizationEvent).paymentAuthorizationId,
        );
        break;
      case EventType.PaymentEncashment:
        await BankingServiceFactory.paymentEncashmentService(widget.appConfiguration).refreshPaymentEncashmentStatus(
          proxyUniverse: event.proxyUniverse,
          paymentAuthorizationId: (event as PaymentEncashmentEvent).paymentAuthorizationId,
          paymentEncashmentId: (event as PaymentEncashmentEvent).paymentEncashmentId,
        );
        break;
      default:
        print("Not yet handled");
    }
  }
}
