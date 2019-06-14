import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:proxy_flutter/config/app_configuration.dart';
import 'package:proxy_flutter/db/firestore_utils.dart';
import 'package:proxy_flutter/model/user_entity.dart';

class UserStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  UserStore(this.appConfiguration)
      : root = FirestoreUtils.rootRef(appConfiguration.firebaseUser);

  Future<UserEntity> fetchUser() async {
    DocumentSnapshot snapshot = await root.get();
    if (snapshot.exists) {
      return UserEntity.fromJson(snapshot.data);
    }
    return null;
  }

  Stream<UserEntity> subscribeForUser() {
    return root.snapshots().map(
          (s) => s.exists ? UserEntity.fromJson(s.data) : null,
        );
  }

  Future<UserEntity> saveUser(UserEntity user) async {
    await root.setData(user.toJson());
    return user;
  }
}
