import 'package:biometric_storage/biometric_storage.dart';
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

  static Future canAuthenticate() async {
    final response = await BiometricStorage().canAuthenticate();
    if (response != CanAuthenticateResponse.success) {
      Utils.showSnackBar('Can\'t authenticate with biometric');
      return false;
    }
    return true;
  }
}
