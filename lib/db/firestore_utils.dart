import 'package:cloud_firestore/cloud_firestore.dart';

mixin FirestoreUtils {
  static const String PROXY_UNIVERSE_NODE = "universe";

  static DocumentReference accountRootRef(String accountId) {
    assert(accountId != null);
    return Firestore.instance.collection('/accounts').document('$accountId');
  }

  static DocumentReference userRootRef(String uid) {
    assert(uid != null);
    return Firestore.instance.collection('/users').document('$uid');
  }
}
