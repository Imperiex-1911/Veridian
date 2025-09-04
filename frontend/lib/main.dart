// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'auth_wrapper.dart'; // The only UI import you need here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veridian',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true, // It's good practice to enable Material 3
      ),
      // The AuthWrapper is the single entry point for your UI.
      home: const AuthWrapper(),
    );
  }
}