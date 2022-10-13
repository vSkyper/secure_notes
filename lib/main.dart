import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/create_password.dart';
import 'package:secured_notes/views/home.dart';

void main() {
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();
final StreamController<bool> _noteStreamCtrl =
    StreamController<bool>.broadcast();
Stream<bool> get onNoteCreated => _noteStreamCtrl.stream;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future fetchNote() async {
    const storage = FlutterSecureStorage();

    String? value = await storage.read(key: 'note');

    if (value != null) {
      _noteStreamCtrl.sink.add(true);
      return;
    }
    _noteStreamCtrl.sink.add(false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secured Notes',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
            if (snapshot.data == true) {
              return const HomePage();
            }
            return CreatePasswordPage(fetchNote: fetchNote);
          }
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
