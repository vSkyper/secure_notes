import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_notes/data.dart';
import 'package:secure_notes/encryption.dart';
import 'package:secure_notes/utils.dart';
import 'package:secure_notes/views/settings.dart';

class Note extends StatefulWidget {
  final Uint8List key_;
  final String note;
  final Function() closeNote;
  const Note({super.key, required this.key_, required this.note, required this.closeNote});

  @override
  State<Note> createState() => _NoteState();
}

class _NoteState extends State<Note> {
  final TextEditingController _noteController = TextEditingController();
  late final Uint8List _key;

  @override
  void initState() {
    super.initState();

    _key = widget.key_;
    _noteController.text = widget.note;
    _noteController.addListener(_saveNote);
  }

  @override
  void dispose() {
    super.dispose();

    _noteController.dispose();
  }

  Future _saveNote() async {
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final String? data = await storage.read(key: 'data');
      if (data == null) return;

      final Map<String, dynamic> dataMap = jsonDecode(data);
      final Data dataDeserialized = Data.fromJson(dataMap);

      final Uint8List ivNote = Encryption.secureRandom(12);

      Data newData = Data(
        dataDeserialized.salt,
        dataDeserialized.ivKey,
        dataDeserialized.key,
        Encryption.toBase64(ivNote),
        Encryption.encrypt(_noteController.text, _key, ivNote),
      );

      await storage.write(key: 'data', value: jsonEncode(newData));
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
          title: const Text('Home'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Settings()),
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: widget.closeNote,
            ),
          ],
        ),
        body: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: TextField(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
