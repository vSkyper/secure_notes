import 'dart:convert' as convert;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/pointycastle.dart';

class Encryption {
  static Uint8List secureRandom(int length) {
    return Uint8List.fromList(List.generate(length, (i) => Random.secure().nextInt(256)));
  }

  static Uint8List fromBase64(String encoded) {
    return convert.base64.decode(encoded);
  }

  static String toBase64(Uint8List decoded) {
    return convert.base64.encode(decoded);
  }

  static String encryptChaCha20Poly1305(String input, Uint8List key, Uint8List iv) {
    final Uint8List bytes = Uint8List.fromList(convert.utf8.encode(input));

    final AEADCipher cipher = AEADCipher('ChaCha20-Poly1305')
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List.fromList([])));

    final Uint8List cipherText = Uint8List.fromList(List.filled(cipher.getOutputSize(bytes.length), 0));
    final int len = cipher.processBytes(bytes, 0, bytes.length, cipherText, 0);

    cipher.doFinal(cipherText, len);

    return toBase64(cipherText);
  }

  static String decryptChaCha20Poly1305(String encrypted, Uint8List key, Uint8List iv) {
    final Uint8List bytes = fromBase64(encrypted);

    final AEADCipher cipher = AEADCipher('ChaCha20-Poly1305')
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List.fromList([])));

    final Uint8List plainText = Uint8List.fromList(List.filled(cipher.getOutputSize(bytes.length), 0));
    final int len = cipher.processBytes(bytes, 0, bytes.length, plainText, 0);

    cipher.doFinal(plainText, len);

    return convert.utf8.decode(plainText.toList(), allowMalformed: true);
  }

  static Uint8List encryptArgon2(String input, Uint8List salt) {
    final Uint8List bytes = Uint8List.fromList(convert.utf8.encode(input));

    final KeyDerivator key = KeyDerivator('argon2')..init(Argon2Parameters(2, salt, desiredKeyLength: 32));

    return key.process(bytes);
  }
}
