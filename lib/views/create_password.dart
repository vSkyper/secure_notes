import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/data.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';

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

    if (!await Utils.canAuthenticate()) return;

    final Uint8List salt = Encryption.secureRandom(32);
    final Uint8List key = Encryption.stretching(_repeatPasswordController.text, salt);
    final Uint8List iv = Encryption.secureRandom(12);

    Data data =
        Data(salt: Encryption.toBase64(salt), iv: Encryption.toBase64(iv), note: Encryption.encrypt('', key, iv));

    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage(
      'key',
      promptInfo: const PromptInfo(
          androidPromptInfo:
              AndroidPromptInfo(title: 'Authentication required', description: 'Confirm password creation')),
    );

    try {
      await biometricStorage.write(Encryption.toBase64(key));
    } on AuthException catch (e) {
      switch (e.code) {
        case (AuthExceptionCode.userCanceled):
          Utils.showSnackBar('You must authenticate with your fingerprint to confirm the creation of a password');
          break;
        case (AuthExceptionCode.unknown):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    }

    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: 'data', value: Data.serialize(data));

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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Repeat Password',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      value != null && value != _passwordController.text ? 'Passwords must be the same' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: createPassword,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
