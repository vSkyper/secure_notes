import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secured_notes/views/home.dart';
import 'package:secured_notes/views/sign_in.dart';

class Auth extends StatefulWidget {
  final VoidCallback fetchNote;
  const Auth({super.key, required this.fetchNote});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool _isNoteEncrypted = true;
  Uint8List _key = Uint8List.fromList([]);
  String _note = '';

  void openNote(Uint8List key, String note) => setState(() {
        _key = key;
        _note = note;
        _isNoteEncrypted = false;
      });

  void closeNote() => setState(() {
        _key = Uint8List.fromList([]);
        _note = '';
        _isNoteEncrypted = true;
      });

  @override
  Widget build(BuildContext context) => _isNoteEncrypted
      ? SignIn(fetchNote: widget.fetchNote, openNote: openNote)
      : Home(password: _key, note: _note, closeNote: closeNote);
}
