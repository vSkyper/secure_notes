import 'package:flutter/material.dart';

class Utils {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static showSnackBar(String? text) {
    if (text == null) return;

    final SnackBar snackBar = SnackBar(
      content: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red,
    );

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
