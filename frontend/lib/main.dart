import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veridian',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Scaffold(appBar: AppBar(title: Text('Veridian')), body: Center(child: Text('Hello Veridian'))),
    );
  }
}