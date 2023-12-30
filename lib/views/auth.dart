import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:secure_notes/views/note.dart';
import 'package:secure_notes/views/sign_in.dart';

class Auth extends StatefulWidget {
  final VoidCallback fetchNote;
  const Auth({super.key, required this.fetchNote});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  Uint8List _key = Uint8List.fromList([]);
  String _note = '';
  bool _isNoteEncrypted = true;

  void _openNote(Uint8List key, String note) => setState(() {
        _key = key;
        _note = note;
        _isNoteEncrypted = false;
      });

  void _closeNote() => setState(() {
        _key = Uint8List.fromList([]);
        _note = '';
        _isNoteEncrypted = true;
      });

  @override
  Widget build(BuildContext context) => _isNoteEncrypted
      ? SignIn(fetchNote: widget.fetchNote, openNote: _openNote)
      : Note(key_: _key, note: _note, closeNote: _closeNote);
}
