import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/data.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

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

    final Uint8List newSaltKey = Encryption.secureRandom(32);
    final Uint8List newKey = Encryption.stretching(_repeatNewPasswordController.text, newSaltKey);

    Data newData = Data(saltKey: Encryption.toBase64(newSaltKey), saltDeviceID: data.saltDeviceID, iv: data.iv);

    await storage.write(key: 'data', value: Data.serialize(newData));
    await storage.write(key: 'key', value: Encryption.toBase64(newKey));

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
