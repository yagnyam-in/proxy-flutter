import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef T JsonToEntity<T>(Map<String, dynamic> json);

class EntityHolder<T> {
  final bool exists;
  final T entity;

  EntityHolder.empty()
      : exists = false,
        entity = null;

  EntityHolder.entity(this.entity) : exists = true;

  EntityHolder.fromSnapshot(DocumentSnapshot snapshot, JsonToEntity fromJson)
      : exists = snapshot.exists,
        entity = fromJson(snapshot.data);
}

mixin FirestoreUtils {
  static const String PROXY_UNIVERSE_NODE = "universe";

  static DocumentReference rootRef(FirebaseUser firebaseUser) {
    assert(firebaseUser != null);
    return Firestore.instance.collection('/users').document('${firebaseUser.uid}');
  }
}
