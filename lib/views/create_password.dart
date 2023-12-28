import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locker/flutter_locker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_notes/data.dart';
import 'package:secure_notes/encryption.dart';
import 'package:secure_notes/utils.dart';

class CreatePassword extends StatefulWidget {
  final VoidCallback fetchNote;
  const CreatePassword({super.key, required this.fetchNote});

  @override
  State<CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
    _repeatPasswordController.dispose();
  }

  Future createPassword() async {
    final bool isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    final Uint8List key = Encryption.secureRandom(32);

    try {
      await FlutterLocker.save(
        SaveSecretRequest(
          key: 'key',
          secret: Encryption.toBase64(key),
          androidPrompt: AndroidPrompt(
              title: 'Authentication required', descriptionLabel: 'Confirm password creation', cancelLabel: "Cancel"),
        ),
      );
    } on LockerException catch (e) {
      switch (e.reason) {
        case (LockerExceptionReason.authenticationCanceled):
          Utils.showSnackBar('You must authenticate with your fingerprint to confirm the creation of a password');
          break;
        case (LockerExceptionReason.authenticationFailed):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    } on PlatformException catch (e) {
      switch (e.message) {
        case ('2'):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    }

    final Uint8List salt = Encryption.secureRandom(32);
    final Uint8List password = Encryption.stretching(_repeatPasswordController.text, salt);

    final Uint8List ivKey = Encryption.secureRandom(12);
    final Uint8List ivNote = Encryption.secureRandom(12);

    Data data = Data(
      Encryption.toBase64(salt),
      Encryption.toBase64(ivKey),
      Encryption.encrypt(Encryption.toBase64(key), password, ivKey),
      Encryption.toBase64(ivNote),
      Encryption.encrypt('', key, ivNote),
    );

    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: 'data', value: jsonEncode(data));

    widget.fetchNote();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Create Password'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Password'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value != null && !RegExp(r'^\S{6,}$').hasMatch(value)
                      ? 'Enter min. 6 characters without whitespaces'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Repeat Password'),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      value != null && value != _passwordController.text ? 'Passwords must be the same' : null,
                  onFieldSubmitted: (_) => createPassword(),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: createPassword,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
