import 'package:flutter/material.dart';
import 'package:flutter_locker/flutter_locker.dart';

class Utils {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static showSnackBar(String text) {
    final SnackBar snackBar = SnackBar(
      content: Text(text),
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
