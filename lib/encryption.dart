import 'dart:convert' as convert;
import 'dart:math';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class Encryption {
  static Uint8List secureRandom(int length) {
    return Uint8List.fromList(
        List.generate(length, (i) => Random.secure().nextInt(256)));
  }

  static Uint8List fromBase64(String encoded) {
    return convert.base64.decode(encoded);
  }

  static Uint8List fromBase16(String encoded) {
    return Uint8List.fromList(hex.decode(encoded));
  }

  static String toBase64(Uint8List decoded) {
    return convert.base64.encode(decoded);
  }

  static String toBase16(Uint8List decoded) {
    return hex.encode(decoded);
  }

  static String encryptAES(String input, Uint8List key, Uint8List iv) {
    final bytes = Uint8List.fromList(convert.utf8.encode(input));

    final BlockCipher cipher = PaddedBlockCipher('AES/CTR/PKCS7')
      ..init(
          true,
          PaddedBlockCipherParameters(
              ParametersWithIV<KeyParameter>(KeyParameter(key), iv), null));

    return toBase64(cipher.process(bytes));
  }

  static String decryptAES(String encrypted, Uint8List key, Uint8List iv) {
    final bytes = fromBase64(encrypted);

    final BlockCipher cipher = PaddedBlockCipher('AES/CTR/PKCS7')
      ..init(
          false,
          PaddedBlockCipherParameters(
              ParametersWithIV<KeyParameter>(KeyParameter(key), iv), null));

    return convert.utf8
        .decode(cipher.process(bytes).toList(), allowMalformed: true);
  }

  static String encryptPBKDF2withHMACSHA3(String input) {
    final bytes = Uint8List.fromList(convert.utf8.encode(input));
    final salt = Uint8List.fromList(convert.utf8.encode('VeryHardToGuessSalt'));

    final KeyDerivator hash = KeyDerivator('SHA3-256/HMAC/PBKDF2')
      ..init(Pbkdf2Parameters(salt, 1028, 32));

    return toBase16(hash.process(bytes));
  }
}
