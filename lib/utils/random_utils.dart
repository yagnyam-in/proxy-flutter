import 'dart:math';

import 'package:uuid/uuid.dart';

class RandomUtils {
  static String randomSecret([int length = 12]) {
    var rand = Random.secure();
    var codeUnits = new List.generate(
      length,
      (index) => rand.nextInt(26) + 65,
    );
    return new String.fromCharCodes(codeUnits);
  }

  static String randomProxyId() {
    Uuid uuidFactory = Uuid();
    var rand = uuidFactory.v4();
    while (int.tryParse(rand[0]) != null) {
      rand = uuidFactory.v4();
    }
    return rand;
  }
}
