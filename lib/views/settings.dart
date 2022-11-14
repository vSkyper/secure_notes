import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';

class Settings extends StatefulWidget {
  final Function updatePassword;
  const Settings({super.key, required this.updatePassword});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatNewPasswordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
    _newPasswordController.dispose();
    _repeatNewPasswordController.dispose();
  }

  Future changePassword() async {
    final bool isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    if (!await Utils.canAuthenticate()) return;

    const FlutterSecureStorage storage = FlutterSecureStorage();

    String? data = await storage.read(key: 'data');
    if (data == null) return;

    Encrypted encrypted = Encrypted.deserialize(data);

    final Uint8List salt = Encryption.fromBase64(encrypted.salt);
    final Uint8List key = Encryption.encryptArgon2(_passwordController.text, salt);
    final Uint8List iv = Encryption.fromBase64(encrypted.iv);

    final String noteDecrypted;
    try {
      noteDecrypted = Encryption.decryptChaCha20Poly1305(encrypted.note, key, iv);
    } on ArgumentError {
      Utils.showSnackBar('Incorrect password');
      return;
    }

    final Uint8List newSalt = Encryption.secureRandom(32);
    final Uint8List newKey = Encryption.encryptArgon2(_repeatNewPasswordController.text, newSalt);
    final Uint8List newIv = Encryption.secureRandom(12);

    Encrypted newEncrypted = Encrypted(
        salt: Encryption.toBase64(newSalt),
        iv: Encryption.toBase64(newIv),
        note: Encryption.encryptChaCha20Poly1305(noteDecrypted, newKey, newIv));

    final BiometricStorageFile biometricStorage = await BiometricStorage().getStorage(
      'key',
      promptInfo: const PromptInfo(
          androidPromptInfo:
              AndroidPromptInfo(title: 'Authentication required', description: 'Confirm your password change')),
    );
    try {
      await biometricStorage.write(Encryption.toBase64(newKey));
    } on AuthException catch (e) {
      switch (e.code) {
        case (AuthExceptionCode.userCanceled):
          Utils.showSnackBar('You must authenticate with your fingerprint to confirm your password change');
          break;
        case (AuthExceptionCode.unknown):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    }

    await storage.write(key: 'data', value: Encrypted.serialize(newEncrypted));

    widget.updatePassword(newKey);

    Utils.showSnackBar('The password has been changed');

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Settings'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Old Password',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value != null && value.isEmpty ? 'The password must not be empty' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null) return null;

                    if (!RegExp(r'^\S{6,}$').hasMatch(value)) return 'Enter min. 6 characters without whitespaces';
                    if (value == _passwordController.text) return 'The new password must be different';

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _repeatNewPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Repeat New Password',
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      value != null && value != _newPasswordController.text ? 'Passwords must be the same' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: changePassword,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Change'),
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
