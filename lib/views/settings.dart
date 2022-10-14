import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/main.dart';
import 'package:secured_notes/utils.dart';

class Settings extends StatefulWidget {
  final Function() encryptNote;
  const Settings({super.key, required this.encryptNote});

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

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    const storage = FlutterSecureStorage();

    String? note = await storage.read(key: 'note');

    if (note == null) {
      navigatorKey.currentState!.pop();
      return;
    }

    final hashPassword =
        sha256.convert(utf8.encode(_passwordController.text.trim())).toString();

    final key = encrypt_package.Key.fromBase16(hashPassword);
    final iv = encrypt_package.IV.fromBase64(note.substring(0, 24));
    final encrypter = encrypt_package.Encrypter(encrypt_package.AES(key));

    try {
      final noteDecrypted = encrypter.decrypt(
          encrypt_package.Encrypted.fromBase64(note.substring(24)),
          iv: iv);

      final newHashPassword = sha256
          .convert(utf8.encode(_repeatNewPasswordController.text.trim()))
          .toString();

      final newKey = encrypt_package.Key.fromBase16(newHashPassword);
      final newIV = encrypt_package.IV.fromSecureRandom(16);
      final newEncrypter =
          encrypt_package.Encrypter(encrypt_package.AES(newKey));

      await storage.write(
          key: 'note',
          value: newIV.base64 +
              newEncrypter.encrypt(noteDecrypted, iv: newIV).base64);

      widget.encryptNote();

      Utils.showSnackBar('Password has been changed');
    } catch (e) {
      Utils.showSnackBar('Wrong Password');
    }

    navigatorKey.currentState!.pop();
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
                  validator: (value) => value != null && value.length < 6
                      ? 'Enter min. 6 characters'
                      : null,
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
