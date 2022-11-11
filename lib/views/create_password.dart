import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
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

    final Uint8List salt = Encryption.secureRandom(32);
    final Uint8List key = Encryption.encryptArgon2(_repeatPasswordController.text.trim(), salt);
    final Uint8List iv = Encryption.secureRandom(12);

    Encrypted encrypted = Encrypted(
        salt: Encryption.toBase64(salt),
        iv: Encryption.toBase64(iv),
        note: Encryption.encryptChaCha20Poly1305('', key, iv));

    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage('key');
    try {
      await biometricStorage.write(Encryption.toBase64(key));
    } on AuthException {
      Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
      return;
    }

    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: 'data', value: Encrypted.serialize(encrypted));

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
                  validator: (value) => value != null && value.length < 6 ? 'Enter min. 6 characters' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _repeatPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
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
