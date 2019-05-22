import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:proxy_flutter/services/contacts_bloc.dart';
import 'package:uuid/uuid.dart';

import 'contact_card.dart';
import 'services/service_factory.dart';
import 'widgets/widget_helper.dart';

final Uuid uuidFactory = Uuid();

enum ContactsPageMode { choose, manage }

class ContactsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ContactsPageMode pageMode;
  final String proxyUniverse;

  ContactsPage({
    Key key,
    @required this.appConfiguration,
    @required this.pageMode,
    this.proxyUniverse,
  }) : super(key: key) {
    print("Constructing ContactsPage");
  }

  factory ContactsPage.choose({
    Key key,
    @required AppConfiguration appConfiguration,
    @required String proxyUniverse,
  }) {
    return ContactsPage(
      appConfiguration: appConfiguration,
      pageMode: ContactsPageMode.choose,
      proxyUniverse: proxyUniverse,
    );
  }

  factory ContactsPage.manage({
    Key key,
    @required AppConfiguration appConfiguration,
  }) {
    return ContactsPage(
      appConfiguration: appConfiguration,
      pageMode: ContactsPageMode.manage,
    );
  }

  @override
  _ContactsPageState createState() {
    return _ContactsPageState(pageMode);
  }
}

class _ContactsPageState extends State<ContactsPage> with WidgetHelper {
  final ContactsPageMode pageMode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ContactsBloc contactsBloc = ServiceFactory.contactsBloc();

  _ContactsPageState(this.pageMode);

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

  bool _showAccount(ContactEntity account) {
    if (pageMode == ContactsPageMode.manage) {
      return true;
    } else {
      return account.proxyUniverse == widget.proxyUniverse;
    }
  }

  String _getTitle(ProxyLocalizations localizations) {
    return pageMode == ContactsPageMode.manage
        ? localizations.manageContactsPageTitle
        : localizations.chooseContactsPageTitle;
  }

  @override
  Widget build(BuildContext context) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getTitle(localizations)),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: StreamBuilder<List<ContactEntity>>(
            stream: contactsBloc.contacts,
            initialData: [],
            builder: (BuildContext context,
                AsyncSnapshot<List<ContactEntity>> snapshot) {
              return accountsWidget(context, snapshot);
            }),
      ),
    );
  }

  Widget accountsWidget(
      BuildContext context, AsyncSnapshot<List<ContactEntity>> accounts) {
    List<Widget> rows = [];
    if (!accounts.hasData) {
      rows.add(
        Center(
          child: Text("Loading"),
        ),
      );
    } else if (accounts.data.isEmpty) {
      rows.add(
        Center(
          child: Text("No Contacts"),
        ),
      );
    } else {
      print("adding ${accounts.data.length} contacts");
      accounts.data.where(_showAccount).forEach((contact) {
        rows.addAll([
          const SizedBox(height: 8.0),
          contactCard(context, contact),
        ]);
      });
    }
    return ListView(
      children: rows,
    );
  }

  Widget contactCard(BuildContext context, ContactEntity contact) {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    return Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: GestureDetector(
        child: ContactCard(contact: contact),
        onTap: () {
          if (pageMode == ContactsPageMode.manage) {
            _edit(context, contact);
          } else {
            Navigator.of(context).pop(contact);
          }
        },
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: localizations.archive,
          color: Colors.red,
          icon: Icons.archive,
          onTap: () => _archiveContact(context, contact),
        ),
      ],
    );
  }

  void _edit(BuildContext context, ContactEntity contact) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String newName = await acceptStringDialog(
      context,
      pageTitle: localizations.contactNameDialogTitle,
      fieldName: localizations.contactName,
      fieldInitialValue: contact.name,
    );
    if (newName != null) {
      contact.name = newName;
      contactsBloc.saveContact(contact);
    }
  }

  void _archiveContact(BuildContext context, ContactEntity contact) async {
    await contactsBloc.deleteContact(contact);
  }

  Future<String> _asyncNameDialog(
      BuildContext context, String initialValue) async {
    ProxyLocalizations localizations = ProxyLocalizations.of(context);
    String name = initialValue;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.contactNameDialogTitle),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration:
                    new InputDecoration(labelText: localizations.contactName),
                onChanged: (value) {
                  name = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(localizations.okButtonLabel),
              onPressed: () {
                Navigator.of(context).pop(name);
              },
            ),
          ],
        );
      },
    );
  }
}
