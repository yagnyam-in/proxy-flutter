import 'dart:async';

import 'package:meta/meta.dart';
import 'package:proxy_flutter/db/event_repo.dart';
import 'package:proxy_flutter/model/event_entity.dart';
import 'package:rxdart/rxdart.dart';

class EventBloc {
  final EventRepo _eventRepo;
  final BehaviorSubject<List<EventEntity>> _eventStream = BehaviorSubject<List<EventEntity>>();

  EventBloc({@required EventRepo eventRepo}) : _eventRepo = eventRepo {
    assert(this._eventRepo != null);
    _refresh();
  }

  void _refresh() {
    print("refreshing events");
    _eventRepo.fetchActiveEvents().then(
      (events) {
        print("Sending ${events.length} events to stream");
        _eventStream.sink.add(events);
      },
      onError: (e) {
        print("Error fetching proxy Accounts $e");
      },
    );
  }

  Stream<List<EventEntity>> get events {
    return _eventStream;
  }

  Future<void> saveEvent(EventEntity event) async {
    print("save event $event");
    await _eventRepo.saveEvent(event);
    _refresh();
  }


  Future<void> deleteEvent(EventEntity event) async {
    print("delete event $event");
    await _eventRepo.deleteEvent(event);
    _refresh();
  }


  void dispose() {
    print('closing _eventStream');
    _eventStream.close();
  }
}
