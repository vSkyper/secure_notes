import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
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

  Future _fetchNote() async {
    try {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      final String? value = await storage.read(key: 'data');

      if (value != null) {
        _noteStreamCtrl.sink.add('noteAvailable');
        return;
      }
      _noteStreamCtrl.sink.add('noteNotAvailable');
    } catch (e) {
      Utils.showSnackBar(e.toString());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        title: 'Secure Notes',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: Utils.messengerKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: darkDynamic ?? ColorScheme.fromSwatch(primarySwatch: Colors.blue),
          scaffoldBackgroundColor: darkDynamic?.background ?? const Color(0xFF18181B),
          appBarTheme: AppBarTheme(
            color: darkDynamic?.background ?? const Color(0xFF18181B),
            foregroundColor: darkDynamic?.onBackground ?? Colors.white,
            elevation: 0,
          ),
          textTheme: TextTheme(
            bodyMedium: const TextStyle(color: Colors.white, fontSize: 15),
            bodyLarge: TextStyle(color: darkDynamic?.onBackground ?? Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
              final Color color = states.contains(MaterialState.error)
                  ? darkDynamic?.onErrorContainer ?? Theme.of(context).colorScheme.error
                  : darkDynamic?.onSurfaceVariant ?? Colors.white;
              return TextStyle(color: color, fontSize: 14);
            }),
            floatingLabelStyle: MaterialStateTextStyle.resolveWith(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.error)) {
                  return TextStyle(color: darkDynamic?.onErrorContainer ?? Theme.of(context).colorScheme.error);
                }
                if (states.contains(MaterialState.focused)) {
                  return TextStyle(color: darkDynamic?.primary ?? Colors.blue);
                }
                return TextStyle(color: darkDynamic?.onSurfaceVariant ?? Colors.white);
              },
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
              backgroundColor: darkDynamic?.surface ?? const Color(0xFF18181B),
              foregroundColor: darkDynamic?.primary ?? Colors.white,
            ),
          ),
          dividerTheme: DividerThemeData(color: darkDynamic?.outlineVariant ?? Colors.grey),
        ),
        home: StreamBuilder(
          initialData: _fetchNote(),
          stream: onNoteCreated,
          builder: (context, snapshot) {
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
