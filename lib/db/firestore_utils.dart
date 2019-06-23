import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


mixin FirestoreUtils {
  static const String PROXY_UNIVERSE_NODE = "universe";

  static DocumentReference rootRef(FirebaseUser firebaseUser) {
    assert(firebaseUser != null);
    return Firestore.instance.collection('/users').document('${firebaseUser.uid}');
  }
}
