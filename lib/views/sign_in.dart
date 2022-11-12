import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';

class SignIn extends StatefulWidget {
  final VoidCallback fetchNote;
  final Function openNote;
  const SignIn({super.key, required this.fetchNote, required this.openNote});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isFingerprintChanged = false;

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  Future signIn() async {
    if (_passwordController.text.isEmpty) return;

    const FlutterSecureStorage storage = FlutterSecureStorage();

    String? data = await storage.read(key: 'data');
    if (data == null) return;

    Encrypted encrypted = Encrypted.deserialize(data);

    final Uint8List salt = Encryption.fromBase64(encrypted.salt);
    final Uint8List key = Encryption.encryptArgon2(_passwordController.text.trim(), salt);
    final Uint8List iv = Encryption.fromBase64(encrypted.iv);

    try {
      final String note = Encryption.decryptChaCha20Poly1305(encrypted.note, key, iv);

      if (_isFingerprintChanged) {
        final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage('key');
        try {
          await biometricStorage.write(Encryption.toBase64(key));
        } on AuthException catch (e) {
          if (e.code == AuthExceptionCode.userCanceled) {
            Utils.showSnackBar(
                'You must authenticate with your fingerprint after changing fingerprints on your device');
            return;
          }
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          return;
        }
      }

      widget.openNote(key, note);
    } on ArgumentError {
      Utils.showSnackBar('Incorrect password');
    }
  }

  Future signInWithFingerprint() async {
    if (!await Utils.canAuthenticate()) return;

    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage('key');
    final String? key;
    try {
      key = await biometricStorage.read();
    } on AuthException catch (e) {
      if (e.code == AuthExceptionCode.userCanceled) {
        return;
      }
      Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
      return;
    }
    if (key == null) {
      _isFingerprintChanged = true;
      Utils.showSnackBar('Sign in with password after changing fingerprints on device');
      return;
    }

    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? data = await storage.read(key: 'data');
    if (data == null) return;

    Encrypted encrypted = Encrypted.deserialize(data);

    final Uint8List keyDecoded = Encryption.fromBase64(key);
    final Uint8List iv = Encryption.fromBase64(encrypted.iv);

    try {
      final String note = Encryption.decryptChaCha20Poly1305(encrypted.note, keyDecoded, iv);

      widget.openNote(keyDecoded, note);
    } on ArgumentError {
      Utils.showSnackBar('Error occurred');
    }
  }

  Future createNewNote() async {
    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage('key');
    biometricStorage.delete();

    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: 'data');

    widget.fetchNote();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Sign in'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              TextField(
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
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: signIn,
                icon: const Icon(Icons.lock_open),
                label: const Text('Sign in'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Forgot password? ',
                  children: [
                    TextSpan(
                      text: 'Create new note ✨',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      recognizer: TapGestureRecognizer()..onTap = createNewNote,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: signInWithFingerprint,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Sign in with Fingerprint'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
