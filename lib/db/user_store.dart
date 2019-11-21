import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:promo/model/user_entity.dart';

class UserStore with ProxyUtils, FirestoreUtils {
  final DocumentReference root;

  UserStore.forUser(FirebaseUser firebaseUser) : root = FirestoreUtils.userRootRef(firebaseUser.uid);

  Future<UserEntity> fetchUser() async {
    DocumentSnapshot snapshot = await root.get();
    return _documentSnapshotToUserEntity(snapshot);
  }

  Stream<UserEntity> subscribeForUser() {
    return root.snapshots().map(_documentSnapshotToUserEntity);
  }

  Future<UserEntity> saveUser(UserEntity user) async {
    await root.setData(user.toJson());
    return user;
  }

  UserEntity _documentSnapshotToUserEntity(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      return UserEntity.fromJson(snapshot.data);
    }
    return null;
  }
}
