import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/banking/deposit_page.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/banking/payment_authorization_page.dart';
import 'package:proxy_flutter/banking/services/banking_service_factory.dart';
import 'package:proxy_flutter/banking/store/event_store.dart';
import 'package:proxy_flutter/banking/widgets/event_card.dart';
import 'package:proxy_flutter/banking/withdrawal_page.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/home_page_navigation.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:uuid/uuid.dart';

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

class _EventsPageState extends LoadingSupportState<EventsPage> with HomePageNavigation {
  final AppConfiguration appConfiguration;
  final ChangeHomePage changeHomePage;

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
        title: new Text(localizations.eventsPageTitle),
      ),
      body: streamBuilder(
        name: "Account Loading",
        stream: _eventStream,
        builder: (context, events) => _events(context, events),
      ),
      bottomNavigationBar: navigationBar(context, HomePage.EventsPage, changeHomePage: changeHomePage),
    );
  }

  Widget _events(BuildContext context, List<EventEntity> events) {
    print("events : $events");
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
          appConfiguration: appConfiguration,
          proxyUniverse: event.proxyUniverse,
          depositId: event.eventId,
        );
      case EventType.Withdrawal:
        return WithdrawalPage(
          appConfiguration: appConfiguration,
          proxyUniverse: event.proxyUniverse,
          withdrawalId: event.eventId,
        );
      case EventType.PaymentAuthorization:
        return PaymentAuthorizationPage(
          appConfiguration: appConfiguration,
          proxyUniverse: event.proxyUniverse,
          paymentAuthorizationId: event.eventId,
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
      default:
        print("Not yet handled");
    }
  }
}
