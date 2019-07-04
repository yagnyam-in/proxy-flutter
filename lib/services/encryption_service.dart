import 'package:encrypt/encrypt.dart';
import 'package:meta/meta.dart';

class EncryptionService {
  // TODO: Revisit
  Key _adjustedKey(String key) {
    String adjusted = key;
    Key adjustedKey = Key.fromUtf8(adjusted);
    int len = adjustedKey.bytes.lengthInBytes;
    if ({16, 24, 32}.contains(len)) {
      return adjustedKey;
    } else if (len < 16) {
      adjusted = adjusted.padRight(16, '0');
    } else if (len < 24) {
      adjusted = adjusted.padRight(24, '0');
    } else if (len < 32) {
      adjusted = adjusted.padRight(32, '0');
    } else {
      throw ArgumentError("Invalid length $len for pass phrase");
    }
    return Key.fromUtf8(adjusted);
  }

  // TODO: Revisit
  Encrypter _cipher({
    @required String encryptionAlgorithm,
    @required String key,
  }) {
    if (encryptionAlgorithm == ENCRYPTION_ALGORITHM) {
      return Encrypter(AES(_adjustedKey(key), mode: AESMode.ctr));
    }
    throw ArgumentError("Invalid encryptionAlgorithm $encryptionAlgorithm");
  }

  // TODO: Take IV as input
  Future<String> encrypt({
    @required String key,
    @required String encryptionAlgorithm,
    @required String plainText,
  }) async {
    final iv = IV.fromLength(16);
    Encrypter encrypter = _cipher(
      encryptionAlgorithm: encryptionAlgorithm,
      key: key,
    );
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  Future<String> decrypt({
    @required String key,
    @required String encryptionAlgorithm,
    @required String cipherText,
  }) async {
    final iv = IV.fromLength(16);
    Encrypter encrypter = _cipher(encryptionAlgorithm: encryptionAlgorithm, key: key);
    return encrypter.decrypt64(cipherText, iv: iv);
  }

  static const String ENCRYPTION_ALGORITHM = 'AES/CTR/NoPadding';
}
