import 'package:firebase_auth/firebase_auth.dart';
import 'package:promo/db/user_store.dart';
import 'package:promo/model/user_entity.dart';

class RegisterService {
  Future<UserEntity> registerUser(FirebaseUser firebaseUser) async {
    UserStore userStore = UserStore.forUser(firebaseUser);
    UserEntity appUser = await userStore.fetchUser();
    if (appUser == null) {
      appUser = await userStore.saveUser(UserEntity.from(firebaseUser));
    }
    return appUser;
  }
}
