import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locker/flutter_locker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_notes/data.dart';
import 'package:secure_notes/encryption.dart';
import 'package:secure_notes/utils.dart';

class CreatePassword extends StatefulWidget {
  final VoidCallback fetchNote;
  const CreatePassword({super.key, required this.fetchNote});

  @override
  State<CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }

  Future createPassword() async {
    try {
      final bool isValid = _formKey.currentState!.validate();
      if (!isValid) return;

      final Uint8List key = Encryption.secureRandom(32);
      await FlutterLocker.save(
        SaveSecretRequest(
          key: 'key',
          secret: Encryption.toBase64(key),
          androidPrompt: AndroidPrompt(
              title: 'Authentication required', descriptionLabel: 'Confirm password creation', cancelLabel: "Cancel"),
        ),
      );

      final Uint8List salt = Encryption.secureRandom(32);
      final Uint8List password = Encryption.stretching(_passwordController.text, salt);

      final Uint8List ivKey = Encryption.secureRandom(12);
      final Uint8List ivNote = Encryption.secureRandom(12);

      Data data = Data(
        Encryption.toBase64(salt),
        Encryption.toBase64(ivKey),
        Encryption.encrypt(Encryption.toBase64(key), password, ivKey),
        Encryption.toBase64(ivNote),
        Encryption.encrypt('', key, ivNote),
      );

      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: 'data', value: jsonEncode(data));

      widget.fetchNote();
    } on LockerException catch (e) {
      switch (e.reason) {
        case (LockerExceptionReason.authenticationCanceled):
          Utils.showSnackBar('You must authenticate with your fingerprint to confirm the creation of a password');
          break;
        case (LockerExceptionReason.authenticationFailed):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    } on PlatformException catch (e) {
      switch (e.message) {
        case ('2'):
          Utils.showSnackBar('Too many attempts or fingerprint reader error. Try again later');
          break;
        default:
          break;
      }
      return;
    } on Exception catch (e) {
      Utils.showSnackBar(e.toString());
      return;
    }
  }

  Future importNote() async {
    try {
      FilePickerResult? selectedFile = await FilePicker.platform.pickFiles(onFileLoading: (status) {
        if (status == FilePickerStatus.picking) {
          setState(() => _isLoading = true);
          return;
        }
        setState(() => _isLoading = false);
      });
      if (selectedFile == null) {
        Utils.showSnackBar('No file selected or storage permission denied');
        return;
      }

      final File file = File(selectedFile.files.single.path!);
      final String data = await file.readAsString();

      final Map<String, dynamic> dataMap = jsonDecode(data);
      Data.fromJson(dataMap);

      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: 'data', value: data);

      widget.fetchNote();
    } on FormatException {
      Utils.showSnackBar('Incorrect file format');
      return;
    } on FileSystemException {
      Utils.showSnackBar('Incorrect file format');
      return;
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
          title: const Text('Create Password'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
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
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Password'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => value != null && !RegExp(r'^\S{6,}$').hasMatch(value)
                          ? 'Enter min. 6 characters without whitespaces'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Confirm Password'),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                          value != null && value != _passwordController.text ? 'Passwords must be the same' : null,
                      onFieldSubmitted: (_) => createPassword(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: createPassword,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Create'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Text(
                    'OR',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : importNote,
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: const Text('Import encrypted note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
