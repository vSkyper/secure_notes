import 'dart:convert';
import 'dart:io';
import 'package:date_format/date_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_notes/data.dart';
import 'package:secure_notes/encryption.dart';
import 'package:secure_notes/utils.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _incorrectPassword = false;

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
  }

  void _passwordChanged() {
    if (_incorrectPassword) _incorrectPassword = false;
  }

  Future _changePassword() async {
    try {
      final bool isValid = _formKey.currentState!.validate();
      if (!isValid) return;

      const FlutterSecureStorage storage = FlutterSecureStorage();
      final String? data = await storage.read(key: 'data');
      if (data == null) return;

      final Map<String, dynamic> dataMap = jsonDecode(data);
      final Data dataDeserialized = Data.fromJson(dataMap);

      final Uint8List salt = Encryption.fromBase64(dataDeserialized.salt);
      final Uint8List password = Encryption.stretching(_passwordController.text, salt);

      final Uint8List ivKey = Encryption.fromBase64(dataDeserialized.ivKey);

      final String key = Encryption.decrypt(dataDeserialized.key, password, ivKey);

      final Uint8List newSalt = Encryption.secureRandom(32);
      final Uint8List newPassword = Encryption.stretching(_newPasswordController.text, newSalt);

      final Uint8List newIvKey = Encryption.secureRandom(12);

      Data newData = Data(
        Encryption.toBase64(newSalt),
        Encryption.toBase64(newIvKey),
        Encryption.encrypt(key, newPassword, newIvKey),
        dataDeserialized.ivNote,
        dataDeserialized.note,
      );

      await storage.write(key: 'data', value: jsonEncode(newData));

      Utils.showSnackBar('The password has been changed');

      _formKey.currentState!.reset();
      FocusManager.instance.primaryFocus?.unfocus();
    } on ArgumentError {
      _incorrectPassword = true;
      _formKey.currentState!.validate();
      return;
    } catch (e) {
      Utils.showSnackBar(e.toString());
      return;
    }
  }

  Future _exportNote() async {
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final String? data = await storage.read(key: 'data');
      if (data == null) return;

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        Utils.showSnackBar('No directory selected or storage permission denied');
        return;
      }

      selectedDirectory += '/${formatDate(DateTime.now(), [yyyy, mm, dd, '_', HH, nn, ss])}.secure_note';

      final File file = File(selectedDirectory);
      await file.writeAsString(data);

      Utils.showSnackBar('Exported successfully');
    } catch (e) {
      Utils.showSnackBar(e.toString());
      return;
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
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
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
                      decoration: const InputDecoration(labelText: 'Old password'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (_) => _passwordChanged(),
                      validator: (value) {
                        if (value != null && value.isEmpty) return 'The password must not be empty';
                        if (_incorrectPassword) return 'Incorrect password';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'New password'),
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
                      controller: _confirmNewPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Confirm new password'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          value != null && value != _newPasswordController.text ? 'Passwords must be the same' : null,
                      onFieldSubmitted: (_) => _changePassword(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Export encrypted note',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _exportNote,
                icon: const Icon(Icons.download),
                label: const Text('Export encrypted note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
