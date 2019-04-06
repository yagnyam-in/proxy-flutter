import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:uuid/uuid.dart';

import 'event_card.dart';

final Uuid uuidFactory = Uuid();

class EventsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final String proxyUniverse;

  EventsPage({Key key, @required this.appConfiguration, this.proxyUniverse}) : super(key: key) {
    print("Constructing EventsPage");
  }

  @override
  _EventsPageState createState() {
    return _EventsPageState();
  }
}

class _EventsPageState extends State<EventsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final EventBloc eventBloc = ServiceFactory.eventBloc();

  _EventsPageState();

  @override
  void initState() {
    super.initState();
  }

  void showToast(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  bool _showEvent(EventEntity event) {
    return widget.proxyUniverse == null || event.proxyUniverse == widget.proxyUniverse;
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
        child: StreamBuilder<List<EventEntity>>(
            stream: eventBloc.events,
            initialData: [],
            builder: (BuildContext context, AsyncSnapshot<List<EventEntity>> snapshot) {
              return eventsWidget(context, snapshot);
            }),
      ),
    );
  }

  Widget eventsWidget(BuildContext context, AsyncSnapshot<List<EventEntity>> events) {
    List<Widget> rows = [];
    if (!events.hasData) {
      rows.add(
        Center(
          child: Text("Loading"),
        ),
      );
    } else if (events.data.isEmpty) {
      rows.add(
        Center(
          child: Text("No Events"),
        ),
      );
    } else {
      print("adding ${events.data.length} events");
      events.data.where(_showEvent).forEach((event) {
        rows.addAll([
          const SizedBox(height: 8.0),
          eventCard(context, event),
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
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        child: EventCard(event: event),
        onTap: () {},
      ),
      secondaryActions: <Widget>[
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
    await eventBloc.deleteEvent(event);
  }
}
