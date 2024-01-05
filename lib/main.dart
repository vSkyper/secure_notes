import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_notes/utils.dart';
import 'package:secure_notes/views/auth.dart';
import 'package:secure_notes/views/create_password.dart';

void main() {
  runApp(const MyApp());
}

final StreamController<String> _noteStreamCtrl = StreamController<String>.broadcast();
Stream<String> get onNoteCreated => _noteStreamCtrl.stream;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _fetchNote() async {
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final String? value = await storage.read(key: 'data');

      if (value != null) {
        _noteStreamCtrl.add('noteAvailable');
        return;
      }
      _noteStreamCtrl.add('noteNotAvailable');
    } catch (e) {
      _noteStreamCtrl.add('noteNotAvailable');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _fetchNote();

    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        title: 'Secure Notes',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: Utils.messengerKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: darkDynamic ??
              ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 74, 49, 121), brightness: Brightness.dark),
          appBarTheme: const AppBarTheme(elevation: 0),
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 15)),
          inputDecorationTheme: const InputDecorationTheme(labelStyle: TextStyle(fontSize: 14)),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
            ),
          ),
        ),
        home: StreamBuilder<String>(
          stream: onNoteCreated,
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data) {
                case 'noteAvailable':
                  return Auth(fetchNote: _fetchNote);
                case 'noteNotAvailable':
                  return CreatePassword(fetchNote: _fetchNote);
              }
            }
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),
      );
    });
  }
}
