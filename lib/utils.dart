import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Utils {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static showSnackBar(String? text) {
    if (text == null) return;

    final snackBar = SnackBar(content: Text(text), backgroundColor: Colors.red);

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

extension BoolParsing on String {
  bool parseBool() {
    return toLowerCase() == 'true';
  }
}

Uint8List decodeHexString(String input) {
  assert(input.length % 2 == 0, 'Input needs to be an even length.');

  return Uint8List.fromList(
    List.generate(
      input.length ~/ 2,
      (i) => int.parse(input.substring(i * 2, (i * 2) + 2), radix: 16),
    ).toList(),
  );
}
