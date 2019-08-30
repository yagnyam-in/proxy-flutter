import 'package:flutter/material.dart';
import 'package:quiver/strings.dart';

import 'model/contact_entity.dart';

class ContactCard extends StatelessWidget {
  final ContactEntity contact;
  final bool highlight;

  const ContactCard({
    Key key,
    this.contact,
    this.highlight = false,
  }) : super(key: key);

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
          color: highlight ? Color.fromRGBO(64, 75, 96, .9) : null,
        ),
        child: makeListTile(context),
      ),
    );
  }

  Widget makeListTile(BuildContext context) {
    String phoneNumber = isNotEmpty(contact.phoneNumber) ? "📱 ${contact.phoneNumber}" : null;
    String email = isNotEmpty(contact.email) ? "✉ ${contact.email}" : null;
    String body = [phoneNumber, email].where((v) => v != null).join("\n");
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        contact.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          body,
        ),
      ),
    );
  }
}
