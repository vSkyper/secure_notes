import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locker/flutter_locker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool _isFingerprintChanged = false;

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

    String? data = await storage.read(key: 'data');
    if (data == null) return;

    Data dataDeserialized = Data.deserialize(data);

    final Uint8List salt = Encryption.fromBase64(dataDeserialized.salt);
    final Uint8List password = Encryption.stretching(_passwordController.text, salt);

    final Uint8List ivKey = Encryption.fromBase64(dataDeserialized.ivKey);

    final String key;
    try {
      key = Encryption.decrypt(dataDeserialized.keyEncrypted, password, ivKey);
    } on ArgumentError {
      Utils.showSnackBar('Incorrect password');
      return;
    }

    if (_isFingerprintChanged && await Utils.canAuthenticate()) {
      try {
        await FlutterLocker.save(
          SaveSecretRequest(
            key: 'key',
            secret: key,
            androidPrompt: AndroidPrompt(
                title: 'Authentication required', descriptionLabel: 'Fingerprints changed', cancelLabel: "Cancel"),
          ),
        );
      } on LockerException catch (e) {
        switch (e.reason) {
          case (LockerExceptionReason.authenticationCanceled):
            Utils.showSnackBar(
                'You must authenticate with your fingerprint after changing fingerprints on your device');
            break;
          case (LockerExceptionReason.authenticationFailed):
            Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
            break;
          default:
            break;
        }
        return;
      } on PlatformException {
        return;
      }
    }

    final Uint8List keyDecoded = Encryption.fromBase64(key);
    final Uint8List ivNote = Encryption.fromBase64(dataDeserialized.ivNote);

    final String note;
    try {
      note = Encryption.decrypt(dataDeserialized.noteEncrypted, keyDecoded, ivNote);
    } on ArgumentError {
      Utils.showSnackBar('Error occurred');
      return;
    }

    widget.openNote(keyDecoded, note);
  }

  Future signInWithFingerprint() async {
    if (!await Utils.canAuthenticate()) return;

    final String? key;
    try {
      key = await FlutterLocker.retrieve(
        RetrieveSecretRequest(
          key: 'key',
          androidPrompt:
              AndroidPrompt(title: 'Authentication required', descriptionLabel: 'Sign in', cancelLabel: 'Cancel'),
          iOsPrompt: IOsPrompt(touchIdText: 'Authentication required'),
        ),
      );
    } on LockerException catch (e) {
      switch (e.reason) {
        case (LockerExceptionReason.authenticationFailed):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        case (LockerExceptionReason.secretNotFound):
          _isFingerprintChanged = true;
          Utils.showSnackBar('Sign in with password after changing fingerprints on device');
          break;
        default:
          break;
      }
      return;
    } on PlatformException {
      return;
    }

    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? encrypted = await storage.read(key: 'data');
    if (encrypted == null) return;

    Data data = Data.deserialize(encrypted);

    final Uint8List keyDecoded = Encryption.fromBase64(key);
    final Uint8List ivNote = Encryption.fromBase64(data.ivNote);

    try {
      final String note = Encryption.decrypt(data.noteEncrypted, keyDecoded, ivNote);

      widget.openNote(keyDecoded, note);
    } on ArgumentError {
      Utils.showSnackBar('Error occurred');
    }
  }

  Future createNewNote() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: 'data');
    await FlutterLocker.delete('key');

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
