import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/service_factory.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/services/event_bloc.dart';
import 'package:proxy_flutter/services/service_factory.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';

import 'event_actions.dart';

class EventPage extends StatefulWidget {
  final EventEntity event;

  const EventPage._internal(this.event, {Key key}) : super(key: key);

  factory EventPage.forEvent(EventEntity event, {Key key}) {
    return EventPage._internal(event, key: key);
  }

  @override
  EventPageState createState() {
    return EventPageState(event);
  }
}

class EventPageState extends LoadingSupportState<EventPage> {
  final EventEntity event;
  final EventBloc eventBloc = ServiceFactory.eventBloc();
  final EventActions eventActions = BankingServiceFactory.eventActions();

  EventPageState(this.event);

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.getTitle(localizations)),
        actions: [
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: new Text(
              localizations.okButtonLabel,
              style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: StreamBuilder<List<EventEntity>>(
            stream: eventBloc.events,
            initialData: [],
            builder: (BuildContext context, AsyncSnapshot<List<EventEntity>> snapshot) {
              return body(context, localizations, snapshot);
            },
          ),
        ),
      ),
    );
  }

  Widget body(BuildContext context, ProxyLocalizations localizations, AsyncSnapshot<List<EventEntity>> snapshot) {
    ThemeData themeData = Theme.of(context);
    EventEntity latestEvent;
    if (snapshot.hasData) {
      latestEvent = snapshot.data.firstWhere((e) => e.id == this.event.id, orElse: () => null);
    }

    List<Widget> rows = [
      const SizedBox(height: 16.0),
      Icon(event.icon(), size: 64.0),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.amount,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          event.getAmountText(localizations),
          style: themeData.textTheme.title,
        ),
      ),
      const SizedBox(height: 24.0),
      Center(
        child: Text(
          localizations.status,
        ),
      ),
      const SizedBox(height: 8.0),
      Center(
        child: Text(
          latestEvent?.getStatus(localizations) ?? localizations.eventDeleted,
          style: themeData.textTheme.title,
        ),
      ),
    ];
    List<EventAction> actions = eventActions.getPossibleActions(latestEvent, localizations);
    if (actions.isNotEmpty) {
      rows.add(const SizedBox(height: 24.0));
      rows.add(ButtonBar(
        alignment: MainAxisAlignment.spaceAround,
        children: actions.map(_actionButton).toList(),
      ));
    }
    return ListView(children: rows);
  }

  Widget _actionButton(EventAction action) {
    return RaisedButton.icon(
      onPressed: () => invoke(action.action),
      icon: Icon(action.icon),
      label: Text(action.title),
    );
  }
}
