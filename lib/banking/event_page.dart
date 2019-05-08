import 'package:flutter/material.dart';
import 'package:proxy_flutter/banking/service_factory.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:proxy_flutter/widgets/async_helper.dart';
import 'package:proxy_flutter/widgets/loading.dart';

import 'event_actions.dart';

class EventPage extends StatefulWidget {
  final EventEntity event;

  const EventPage({Key key, @required this.event}) : super(key: key);

  @override
  EventPageState createState() {
    return EventPageState(event: event);
  }
}

class EventPageState extends LoadingSupportState<EventPage> {
  final EventEntity event;
  final EventActions eventActions;

  EventPageState({@required this.event}) : eventActions = BankingServiceFactory.eventActions();

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
          child: body(context, localizations),
        ),
      ),
    );
  }

  Widget body(BuildContext context, ProxyLocalizations localizations) {
    ThemeData themeData = Theme.of(context);

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
          event.getStatus(localizations),
          style: themeData.textTheme.title,
        ),
      ),
    ];
    List<EventAction> actions = eventActions.getPossibleActions(event, localizations);
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
