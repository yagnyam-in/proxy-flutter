
import 'dart:math';

class RandomUtils {

  static String randomSecret([int length = 8]) {
    var rand = Random.secure();
    var codeUnits = new List.generate(
      length,
          (index) => rand.nextInt(26) + 65,
    );

    return new String.fromCharCodes(codeUnits);
  }

}