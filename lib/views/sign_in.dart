import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:secured_notes/data.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    signInWithFingerprint();
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  Future signIn() async {
    final bool isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    const FlutterSecureStorage storage = FlutterSecureStorage();

    String? encrypted = await storage.read(key: 'data');
    if (encrypted == null) return;
    String? keyStorage = await storage.read(key: 'key');
    if (keyStorage == null) return;

    Data data = Data.deserialize(encrypted);

    final Uint8List saltKey = Encryption.fromBase64(data.saltKey);
    final Uint8List key = Encryption.stretching(_passwordController.text, saltKey);

    if (!listEquals(key, Encryption.fromBase64(keyStorage))) {
      Utils.showSnackBar('Incorrect password');
      return;
    }

    widget.openNote();
  }

  Future signInWithFingerprint() async {
    if (!await Utils.canAuthenticate()) return;

    final LocalAuthentication auth = LocalAuthentication();

    final bool didAuthenticate;
    try {
      didAuthenticate = await auth.authenticate(
          localizedReason: 'Sign in', options: const AuthenticationOptions(biometricOnly: true));
    } on PlatformException catch (e) {
      if (e.code == auth_error.lockedOut) {
        Utils.showSnackBar('Too many attempts. Try again later');
      }
      return;
    }

    if (!didAuthenticate) return;

    widget.openNote();
  }

  Future createNewNote() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: 'data');
    await storage.delete(key: 'key');
    await storage.delete(key: 'note');

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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => value != null && value.isEmpty ? 'The password must not be empty' : null,
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Forgot password? ',
                  children: [
                    TextSpan(
                      text: 'Create new note',
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
              IconButton(
                onPressed: signInWithFingerprint,
                icon: const Icon(Icons.fingerprint),
                iconSize: 45,
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
