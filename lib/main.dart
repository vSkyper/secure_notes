import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secured_notes/utils.dart';
import 'package:secured_notes/views/auth.dart';
import 'package:secured_notes/views/create_password.dart';

void main() {
  runApp(const MyApp());
}

final StreamController<String> _noteStreamCtrl = StreamController<String>.broadcast();
Stream<String> get onNoteCreated => _noteStreamCtrl.stream;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future fetchNote() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();

    String? value = await storage.read(key: 'data');

    if (value != null) {
      _noteStreamCtrl.sink.add('noteAvailable');
      return;
    }
    _noteStreamCtrl.sink.add('noteNotAvailable');
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Secured Notes',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: Utils.messengerKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme ?? ColorScheme.fromSwatch(primarySwatch: Colors.blue),
          scaffoldBackgroundColor: darkColorScheme?.background ?? const Color(0xFF18181B),
          appBarTheme: AppBarTheme(
            color: darkColorScheme?.background ?? const Color(0xFF18181B),
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
                  return Auth(fetchNote: fetchNote);
                case 'noteNotAvailable':
                  return CreatePassword(fetchNote: fetchNote);
              }
            }
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),
      );
    });
  }
}
