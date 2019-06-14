import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/contact_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:proxy_flutter/modify_proxy_page.dart';
import 'package:uuid/uuid.dart';

import 'contact_card.dart';
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
    return _ContactsPageState(appConfiguration, pageMode);
  }
}

class _ContactsPageState extends State<ContactsPage> with WidgetHelper {
  final AppConfiguration appConfiguration;
  final ContactsPageMode pageMode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ContactStore _contactStore;
  Stream<List<ContactEntity>> _contactsStream;

  _ContactsPageState(this.appConfiguration, this.pageMode)
      : _contactStore = ContactStore(appConfiguration);

  @override
  void initState() {
    super.initState();
    _contactsStream = _contactStore.subscribeForContacts();
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
            stream: _contactsStream,
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
      actionPane: SlidableDrawerActionPane(),
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
    await Navigator.of(context).push(
      new MaterialPageRoute<ContactEntity>(
        builder: (context) => ModifyProxyPage(appConfiguration, contact),
        fullscreenDialog: true,
      ),
    );
  }

  void _archiveContact(BuildContext context, ContactEntity contact) async {
    await _contactStore.archiveContact(contact);
  }
}
