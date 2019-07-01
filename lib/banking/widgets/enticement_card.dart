import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/enticement.dart';

class EnticementCard extends StatelessWidget {
  final Enticement enticement;
  final VoidCallback setup;
  final VoidCallback dismiss;
  final bool dismissable;

  const EnticementCard({
    Key key,
    @required this.enticement,
    @required this.setup,
    @required this.dismiss,
    bool dismissable,
  })  : dismissable = dismissable ?? true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    print(enticement);
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
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
      title: Text(
        '💡 ' + enticement.getTitle(localizations),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            Text(
              enticement.getDescription(localizations),
            ),
            ButtonBar(
              children: <Widget>[
                if (dismissable) FlatButton(
                  child: Text(localizations.dismissButtonLabel),
                  onPressed: dismiss,
                ),
                RaisedButton(
                  child: Text(localizations.proceedButtonLabel),
                  onPressed: setup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
