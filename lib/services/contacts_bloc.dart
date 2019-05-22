import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/contacts_repo.dart';
import 'package:proxy_flutter/model/contact_entity.dart';
import 'package:rxdart/rxdart.dart';

class ContactsBloc {
  final ContactsRepo _contactsRepo;
  final BehaviorSubject<List<ContactEntity>> _contactStreamController =
      BehaviorSubject<List<ContactEntity>>();

  ContactsBloc({@required ContactsRepo contactsRepo})
      : _contactsRepo = contactsRepo {
    assert(this._contactsRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing contacts");
    _contactsRepo.fetchAllContacts().then(
      (r) {
        _contactStreamController.sink.add(r);
      },
      onError: (e) {
        print("Failed to fetch contacts");
      },
    );
  }

  Stream<List<ContactEntity>> get contacts {
    return _contactStreamController;
  }

  Future<void> saveContact(ContactEntity contact) async {
    _contactsRepo.save(contact);
    _refresh();
  }

  Future<void> deleteContact(ContactEntity contact) async {
    _contactsRepo.delete(contact);
    _refresh();
  }


  void dispose() {
    _contactStreamController?.close();
  }
}
