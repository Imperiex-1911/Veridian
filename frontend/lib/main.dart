import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/audit_wizard_screen.dart';
import 'screens/rebates_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veridian',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/dashboard': (context) =>  HomeScreen(),
        '/audit': (context) =>  AuditWizardScreen(),
        '/rebates': (context) =>  RebatesScreen(),
      },
    );
  }
}