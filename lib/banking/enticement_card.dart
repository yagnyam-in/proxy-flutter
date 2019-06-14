import 'package:flutter/material.dart';
import 'package:proxy_flutter/model/enticement.dart';

class EnticementCard extends StatelessWidget {
  final Enticement enticement;

  const EnticementCard({Key key, this.enticement}) : super(key: key);

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
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        enticement.title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          enticement.description,
        ),
      ),
    );
  }
}
