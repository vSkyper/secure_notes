import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/main.dart';
import 'package:crypto/crypto.dart';

class CreatePasswordPage extends StatefulWidget {
  final VoidCallback fetchNote;
  const CreatePasswordPage({super.key, required this.fetchNote});

  @override
  State<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends State<CreatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _passwordController.text = '';
    _repeatPasswordController.text = '';
    _passwordController.dispose();
    _repeatPasswordController.dispose();
  }

  Future createPassword() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    final hashPassword = sha256
        .convert(utf8.encode(_repeatPasswordController.text.trim()))
        .toString();

    final key = Encryption.fromBase16(hashPassword);
    final iv = Encryption.fromSecureRandom(16);

    const storage = FlutterSecureStorage();

    await storage.write(
        key: 'note',
        value: Encryption.toBase64(iv) +
            Encryption.encrypt('Enter your message :)', key, iv));

    widget.fetchNote();
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Create Password',
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
                    labelText: 'Password',
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
                      value != null && value != _passwordController.text
                          ? 'Passwords must be the same'
                          : null,
                ),
                const SizedBox(height: 15),
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
