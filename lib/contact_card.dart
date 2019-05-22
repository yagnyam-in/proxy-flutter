import 'package:flutter/material.dart';

import 'model/contact_entity.dart';

class ContactCard extends StatelessWidget {
  final ContactEntity contact;

  const ContactCard({Key key, this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(contact);
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
        contact.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          contact.proxyId.id,
        ),
      ),
      trailing: Text(contact.proxyUniverse),
    );
  }
}
