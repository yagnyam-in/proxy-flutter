import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/contact_store.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:uuid/uuid.dart';

import 'contact_card.dart';
import 'modify_contact_page.dart';
import 'services/enticement_factory.dart';
import 'widgets/async_helper.dart';
import 'widgets/enticement_helper.dart';
import 'widgets/loading.dart';

final Uuid uuidFactory = Uuid();

enum ContactsPageMode { singleSelection, multiSelection, manage }

class ContactsPage extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final ContactsPageMode pageMode;

  ContactsPage(
    this.appConfiguration, {
    Key key,
    @required this.pageMode,
  }) : super(key: key) {
    print("Constructing ContactsPage");
  }

  factory ContactsPage.singleSelection(AppConfiguration appConfiguration, {Key key}) {
    return ContactsPage(
      appConfiguration,
      pageMode: ContactsPageMode.singleSelection,
    );
  }

  factory ContactsPage.multiSelection(AppConfiguration appConfiguration, {Key key}) {
    return ContactsPage(
      appConfiguration,
      pageMode: ContactsPageMode.multiSelection,
    );
  }

  factory ContactsPage.manage({
    Key key,
    @required AppConfiguration appConfiguration,
  }) {
    return ContactsPage(
      appConfiguration,
      pageMode: ContactsPageMode.manage,
    );
  }

  @override
  _ContactsPageState createState() {
    return _ContactsPageState(appConfiguration, pageMode);
  }
}

class _ContactsPageState extends LoadingSupportState<ContactsPage> with EnticementHelper {
  final AppConfiguration appConfiguration;
  final ContactsPageMode pageMode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ContactStore _contactStore;

  bool loading = false;
  Stream<List<ContactEntity>> _contactsStream;
  Set<ContactEntity> _selectedContacts = {};

  _ContactsPageState(this.appConfiguration, this.pageMode) : _contactStore = ContactStore(appConfiguration);

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
        actions: [
          if (pageMode == ContactsPageMode.multiSelection)
            new FlatButton(
              onPressed: () => Navigator.of(context).pop(_selectedContacts),
              child: new Text(
                localizations.okButtonLabel,
                style: Theme.of(context).textTheme.subhead.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
      body: BusyChildWidget(
        loading: loading,
        child: streamBuilder(
          stream: _contactsStream,
          initialData: [],
          builder: (context, contacts) => accountsWidget(context, contacts),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newContact(context),
        icon: Icon(Icons.add),
        label: Text(localizations.newContactFabLabel),
      ),
    );
  }

  Widget accountsWidget(BuildContext context, List<ContactEntity> contacts) {
    print("adding ${contacts.length} contacts");

    if (contacts.isEmpty) {
      return ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 4.0),
          enticementCard(context, EnticementFactory.noContacts, cancellable: false),
        ],
      );
    }

    List<Widget> rows = contacts.where((contact) {
      return contact.isUsable || pageMode == ContactsPageMode.manage;
    }).expand((contact) {
      return [
        const SizedBox(height: 4.0),
        contactCard(context, contact),
      ];
    }).toList();
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
        child: ContactCard(
          contact: contact,
          highlight: _selectedContacts.contains(contact),
        ),
        onTap: () {
          if (pageMode == ContactsPageMode.manage) {
            _edit(context, contact);
          } else if (pageMode == ContactsPageMode.singleSelection) {
            Navigator.of(context).pop(contact);
          } else {
            setState(() {
              if (_selectedContacts.contains(contact)) {
                _selectedContacts.remove(contact);
              } else {
                _selectedContacts.add(contact);
              }
            });
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

  Future<void> _edit(BuildContext context, ContactEntity contact) async {
    await Navigator.of(context).push(
      new MaterialPageRoute<ContactEntity>(
        builder: (context) => ModifyContactPage(appConfiguration, contact),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _newContact(BuildContext context) async {
    await Navigator.of(context).push(
      new MaterialPageRoute<ContactEntity>(
        builder: (context) => ModifyContactPage(appConfiguration, ContactEntity(id: uuidFactory.v4())),
        fullscreenDialog: true,
      ),
    );
  }

  void _archiveContact(BuildContext context, ContactEntity contact) async {
    await _contactStore.archiveContact(contact);
  }

  @override
  Future<void> createAccountAndDeposit(BuildContext context) {
    return null;
  }

  @override
  Future<void> createPaymentAuthorization(BuildContext context) {
    return null;
  }

  @override
  Future<void> verifyEmail(BuildContext context, String email) {
    return null;
  }

  @override
  Future<void> verifyPhoneNumber(BuildContext context, String phoneNumber) {
    return null;
  }
}
