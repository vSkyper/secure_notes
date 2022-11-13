import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/encrypted.dart';
import 'package:secured_notes/encryption.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/settings.dart';

class Home extends StatefulWidget {
  final Uint8List password;
  final String note;
  final VoidCallback closeNote;
  const Home({super.key, required this.password, required this.note, required this.closeNote});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _noteController.text = widget.note;
    _noteController.addListener(saveNote);
  }

  @override
  void dispose() {
    super.dispose();

    _noteController.dispose();
  }

  Future saveNote() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? data = await storage.read(key: 'data');
    if (data == null) return;

    final Uint8List iv = Encryption.secureRandom(12);

    Encrypted encrypted = Encrypted(
        salt: Encrypted.deserialize(data).salt,
        iv: Encryption.toBase64(iv),
        note: Encryption.encryptChaCha20Poly1305(_noteController.text.trim(), widget.password, iv));

    await storage.write(key: 'data', value: Encrypted.serialize(encrypted));
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
            IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Settings(closeNote: widget.closeNote)),
              ),
            ),
            IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'Logout',
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.closeNote,
            ),
          ],
        ),
        body: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            physics: const BouncingScrollPhysics(),
            child: Column(
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
                  keyboardType: TextInputType.multiline,
                  minLines: 8,
                  maxLines: null,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Enter your note here",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
