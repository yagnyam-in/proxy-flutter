import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:promo/authorizations_helper.dart';
import 'package:promo/banking/db/event_store.dart';
import 'package:promo/banking/events_helper.dart';
import 'package:promo/banking/model/deposit_event.dart';
import 'package:promo/banking/model/event_entity.dart';
import 'package:promo/banking/model/payment_authorization_event.dart';
import 'package:promo/banking/model/payment_encashment_event.dart';
import 'package:promo/banking/model/withdrawal_event.dart';
import 'package:promo/banking/services/banking_service_factory.dart';
import 'package:promo/banking/widgets/event_card.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/home_page_navigation.dart';
import 'package:promo/localizations.dart';
import 'package:promo/services/enticement_factory.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/enticement_helper.dart';
import 'package:uuid/uuid.dart';

import 'deposit_helper.dart';
import 'payment_authorization_helper.dart';
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
    with
        HomePageNavigation,
        EnticementHelper,
        DepositHelper,
        PaymentAuthorizationHelper,
        AccountHelper,
        EventsHelper,
        AuthorizationsHelper {
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
    _eventStream = _eventStore.subscribeForEvents(proxyUniverse: appConfiguration.proxyUniverse);
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
    // print("events : $events");
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
          _eventCard(context, account),
        ];
      }).toList(),
    );
  }

  Widget _eventCard(BuildContext context, EventEntity event) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        child: EventCard(event: event),
        onTap: () => launchEvent(context, event),
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

  void _archiveEvent(BuildContext context, EventEntity event) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    if (!event.completed) {
      showToast(localizations.withdrawalNotYetComplete);
    }
    await _eventStore.delete(event);
  }

  Future<void> _refreshEvent(BuildContext context, EventEntity event) async {
    switch (event.eventType) {
      case EventType.Deposit:
        await BankingServiceFactory.depositService(widget.appConfiguration).refreshDepositByInternalId(
          (event as DepositEvent).depositInternalId,
        );
        break;
      case EventType.Withdrawal:
        await BankingServiceFactory.withdrawalService(widget.appConfiguration).refreshWithdrawalByInternalId(
          (event as WithdrawalEvent).withdrawalInternalId,
        );
        break;
      case EventType.PaymentAuthorization:
        await BankingServiceFactory.paymentAuthorizationService(widget.appConfiguration)
            .refreshPaymentAuthorizationByInternalId(
          (event as PaymentAuthorizationEvent).paymentAuthorizationInternalId,
        );
        break;
      case EventType.PaymentEncashment:
        await BankingServiceFactory.paymentEncashmentService(widget.appConfiguration)
            .refreshPaymentEncashmentByInternalId((event as PaymentEncashmentEvent).paymentEncashmentInternalId);
        break;
      default:
        print("Not yet handled");
    }
  }
}
