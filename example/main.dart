import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'rooms_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: String.fromEnvironment('API_KEY'),
          projectId: String.fromEnvironment('PROJECT_ID'),
          messagingSenderId: String.fromEnvironment('MESSAGING_SENDER_ID'),
          appId: kIsWeb
              ? String.fromEnvironment('APP_ID_WEB')
              : String.fromEnvironment('APP_ID_ANDROID')));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RoomsPage(),
    );
  }
}
