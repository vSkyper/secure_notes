import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/main.dart';
import 'package:secured_notes/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDecrypted = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _noteController.dispose();
    _passwordController.dispose();
  }

  Future saveNote() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    final hashPassword =
        md5.convert(utf8.encode(_passwordController.text.trim())).toString();

    final key = encrypt_package.Key.fromUtf8(hashPassword);
    final iv = encrypt_package.IV.fromLength(16);
    final encrypter = encrypt_package.Encrypter(encrypt_package.AES(key));

    const storage = FlutterSecureStorage();

    await storage.write(
        key: 'password', value: hashPassword);
    await storage.write(
        key: 'note', value: encrypter.encrypt(_noteController.text.trim(), iv: iv).base64);

    Utils.showSnackBar('Save note');

    navigatorKey.currentState!.pop();
  }

  Future decryptNote() async {
    if (_passwordController.text.isEmpty) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    final hashPassword =
        md5.convert(utf8.encode(_passwordController.text.trim())).toString();

    final key = encrypt_package.Key.fromUtf8(hashPassword);
    final iv = encrypt_package.IV.fromLength(16);
    final encrypter = encrypt_package.Encrypter(encrypt_package.AES(key));

    const storage = FlutterSecureStorage();

    String note = await storage.read(key: 'note') ?? '';

    try {
      _noteController.text =
          encrypter.decrypt(encrypt_package.Encrypted.fromBase64(note), iv: iv);

      _passwordController.text = '';

      setState(() {
        _isDecrypted = true;
      });
    } catch (e) {
      Utils.showSnackBar('Wrong Password');
    }

    navigatorKey.currentState!.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home'),
        actions: [
          IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => Container()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        physics: const BouncingScrollPhysics(),
        child: _isDecrypted
            ? Form(
              key: _formKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _noteController,
                      maxLines: 8,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Enter your note here",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) =>
                      value != null && value.isEmpty
                          ? 'Enter a note'
                          : null,
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: saveNote,
                      icon: const Icon(Icons.save),
                      label: const Text('Save note'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ],
                ),
            )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: decryptNote,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Decrypt'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
