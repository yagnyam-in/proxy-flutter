import 'package:flutter/material.dart';
import 'package:promo/localizations.dart';
import 'package:promo/banking/model/event_entity.dart';

class EventCard extends StatelessWidget {
  final EventEntity event;

  EventCard({Key key, this.event}) : super(key: key) {
    assert(event != null);
  }

  @override
  Widget build(BuildContext context) {
    print(event);
    return makeCard(context);
  }

  Widget makeCard(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
            // color: Color.fromRGBO(64, 75, 96, .9),
            ),
        child: makeListTile(context),
      ),
    );
  }

  Widget makeListTile(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String title = event.getTitle(localizations);
    if (event.completed) {
      title += ' \u{2714}';
    }
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          event.getSubTitle(localizations),
        ),
      ),
      trailing: Text(
        event.getAmountAsText(localizations),
        style: themeData.textTheme.title,
      ),
    );
  }
}
