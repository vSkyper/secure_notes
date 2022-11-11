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
  String _note = '';

  void openNote(String note) => setState(() {
        _note = note;
        _isNoteEncrypted = false;
      });

  void closeNote() => setState(() {
        _note = '';
        _isNoteEncrypted = true;
      });

  @override
  Widget build(BuildContext context) => _isNoteEncrypted
      ? SignIn(fetchNote: widget.fetchNote, openNote: openNote)
      : Home(note: _note, closeNote: closeNote);
}
