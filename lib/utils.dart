import 'package:flutter/material.dart';
import 'package:flutter_locker/flutter_locker.dart';

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

  static Future canAuthenticate() async {
    try {
      if (await FlutterLocker.canAuthenticate() ?? false) {
        return true;
      }
      Utils.showSnackBar('Can\'t authenticate with biometric');
      return false;
    } catch (e) {
      Utils.showSnackBar(e.toString());
      return false;
    }
  }
}
