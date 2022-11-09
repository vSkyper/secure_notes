import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/settings.dart';

class HomePage extends StatefulWidget {
  final VoidCallback fetchNote;
  const HomePage({super.key, required this.fetchNote});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDecrypted = false;
  String _password = '';
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _noteController.text = '';
    _passwordController.text = '';
    _noteController.dispose();
    _passwordController.dispose();
  }

  Future saveNote() async {
    if (_noteController.text.isEmpty) return;

    final salt = Encryption.secureRandom(32);
    final hashPassword = Encryption.encryptArgon2(_password, salt);
    final iv = Encryption.secureRandom(12);

    Encrypted encrypted = Encrypted(
        salt: Encryption.toBase64(salt),
        iv: Encryption.toBase64(iv),
        note: Encryption.encryptChaCha20Poly1305(
            _noteController.text.trim(), hashPassword, iv));

    const storage = FlutterSecureStorage();

    await storage.write(key: 'data', value: Encrypted.serialize(encrypted));

    Utils.showSnackBar('The note has been saved');
  }

  Future decryptNote() async {
    if (_passwordController.text.isEmpty) return;

    const storage = FlutterSecureStorage();

    String? note = await storage.read(key: 'data');

    if (note == null) {
      return;
    }

    Encrypted encrypted = Encrypted.deserialize(note);

    final salt = Encryption.fromBase64(encrypted.salt);
    final hashPassword =
        Encryption.encryptArgon2(_passwordController.text.trim(), salt);
    final iv = Encryption.fromBase64(encrypted.iv);

    try {
      _noteController.text =
          Encryption.decryptChaCha20Poly1305(encrypted.note, hashPassword, iv);

      _password = _passwordController.text;
      _passwordController.text = '';

      setState(() {
        _isDecrypted = true;
      });
    } on ArgumentError {
      Utils.showSnackBar('Incorrect password');
    }
  }

  void closeNote() {
    _noteController.text = '';
    _passwordController.text = '';
    _password = '';
    setState(() {
      _isDecrypted = false;
    });
  }

  Future createNewNote() async {
    const storage = FlutterSecureStorage();
    storage.delete(key: 'data');
    widget.fetchNote();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Home'),
          actions: [
            if (_isDecrypted)
              IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => Settings(closeNote: closeNote)),
                ),
              ),
            if (_isDecrypted)
              IconButton(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => closeNote(),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          physics: const BouncingScrollPhysics(),
          child: _isDecrypted
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your note',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 8,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Enter your note here",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                )
              : Column(
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
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        text: 'Forgot password? ',
                        children: [
                          TextSpan(
                            text: 'Create new note ✨',
                            style: const TextStyle(color: Colors.blue),
                            recognizer: TapGestureRecognizer()
                              ..onTap = createNewNote,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
