import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';

class Settings extends StatefulWidget {
  final VoidCallback closeNote;
  const Settings({super.key, required this.closeNote});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatNewPasswordController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _passwordController.text = '';
    _newPasswordController.text = '';
    _repeatNewPasswordController.text = '';
    _passwordController.dispose();
    _newPasswordController.dispose();
    _repeatNewPasswordController.dispose();
  }

  Future changePassword() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    const storage = FlutterSecureStorage();

    String? note = await storage.read(key: 'data');

    if (note == null) {
      return;
    }

    Encrypted encrypted = Encrypted.deserialize(note);

    final salt = Encryption.fromBase64(encrypted.salt);
    final hashPassword =
        Encryption.encryptArgon2(_passwordController.text.trim(), salt);

    final key = Encryption.fromBase16(hashPassword);
    final iv = Encryption.fromBase64(encrypted.iv);

    try {
      final noteDecrypted =
          Encryption.decryptChaCha20Poly1305(encrypted.note, key, iv);

      final newSalt = Encryption.secureRandom(32);
      final newHashPassword = Encryption.encryptArgon2(
          _repeatNewPasswordController.text.trim(), newSalt);

      final newKey = Encryption.fromBase16(newHashPassword);
      final newIV = Encryption.secureRandom(12);

      Encrypted newEncrypted = Encrypted(
          salt: Encryption.toBase64(newSalt),
          iv: Encryption.toBase64(newIV),
          note:
              Encryption.encryptChaCha20Poly1305(noteDecrypted, newKey, newIV));

      await storage.write(
          key: 'data', value: Encrypted.serialize(newEncrypted));

      widget.closeNote();

      Utils.showSnackBar('The password has been changed');

      if (!mounted) return;
      Navigator.of(context).pop();
    } on ArgumentError {
      Utils.showSnackBar('Incorrect password');
    }
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
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),
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

                    if (value.length < 6) {
                      return 'Enter min. 6 characters';
                    } 

                    if (value == _passwordController.text) {
                      return 'The new password must be different';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _repeatNewPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
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
                      value != null && value != _newPasswordController.text
                          ? 'Passwords must be the same'
                          : null,
                ),
                const SizedBox(height: 15),
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
