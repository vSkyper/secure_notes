import 'package:flutter/material.dart';
import 'package:secured_notes/utils.dart';

void main() {
  runApp(const MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Stream<bool?> fetchPassword() async* {

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
        stream:fetchPassword(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasError) {
            return const Scaffold(
                body: Center(child: Text('Something went wrong :(')));
          } else if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const AuthPage();
          }
        },,
    );
  }
}