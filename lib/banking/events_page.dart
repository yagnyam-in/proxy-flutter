import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/banking/banking_service_factory.dart';
import 'package:proxy_flutter/banking/deposit_page.dart';
import 'package:proxy_flutter/banking/model/deposit_event.dart';
import 'package:proxy_flutter/banking/model/withdrawal_event.dart';
import 'package:proxy_flutter/banking/store/event_store.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/banking/model/event_entity.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:uuid/uuid.dart';

import 'event_card.dart';

final Uuid uuidFactory = Uuid();

class EventsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;

  EventsPage({
    Key key,
    @required this.appConfiguration,
  }) : super(key: key) {
    assert(appConfiguration != null);
    print("Constructing EventsPage");
  }

  @override
  _EventsPageState createState() {
    return _EventsPageState(appConfiguration);
  }
}

class _EventsPageState extends LoadingSupportState<EventsPage> {
  final AppConfiguration appConfiguration;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EventStore _eventStore;
  Stream<QuerySnapshot> _eventStream;

  _EventsPageState(this.appConfiguration)
      : _eventStore = EventStore(firebaseUser: appConfiguration.firebaseUser);

  @override
  void initState() {
    super.initState();
    _eventStream = _eventStore.fetchEvents(proxyUniverse: appConfiguration.proxyUniverse);
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
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _eventStream,
          builder: eventsWidget,
        ),
      ),
    );
  }

  Widget eventsWidget(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> events,
  ) {
    List<Widget> rows = [];
    if (!events.hasData) {
      rows.add(
        Center(
          child: Text("Loading"),
        ),
      );
    } else if (events.data.documents.isEmpty) {
      rows.add(
        Center(
          child: Text("No Events"),
        ),
      );
    } else {
      print("adding ${events.data.documents.length} events");
      events.data.documents.forEach((event) {
        rows.addAll([
          const SizedBox(height: 8.0),
          eventCard(context, EventStore.fromJson(event.data)),
        ]);
      });
    }
    return ListView(
      children: rows,
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
          onTap: () => invoke(() => _refreshEvent(context, event)),
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
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => _eventPage(context, event),
      ),
    );
  }

  Widget _eventPage(BuildContext context, EventEntity event) {
    switch (event.eventType) {
      case EventType.Deposit:
        return DepositPage(
          appConfiguration: appConfiguration,
          proxyUniverse: event.proxyUniverse,
          depositId: event.eventId,
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
      case EventType.Withdraw:
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
