import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/create_password.dart';
import 'package:secured_notes/views/home.dart';

void main() {
  runApp(const MyApp());
}

final StreamController<String> _noteStreamCtrl =
    StreamController<String>.broadcast();
Stream<String> get onNoteCreated => _noteStreamCtrl.stream;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future fetchNote() async {
    const storage = FlutterSecureStorage();

    String? value = await storage.read(key: 'note');

    if (value != null) {
      _noteStreamCtrl.sink.add('noteAvailable');
      return;
    }
    _noteStreamCtrl.sink.add('noteNotAvailable');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secured Notes',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Utils.messengerKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF18181B),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF18181B),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyText2: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      home: StreamBuilder(
        initialData: fetchNote(),
        stream: onNoteCreated,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            switch (snapshot.data) {
              case 'noteAvailable':
                return HomePage(fetchNote: fetchNote);
              case 'noteNotAvailable':
                return CreatePasswordPage(fetchNote: fetchNote);
              default:
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
            }
          }
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
