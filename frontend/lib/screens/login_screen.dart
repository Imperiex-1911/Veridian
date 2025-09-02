// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _showProfileForm = false; // This will control which form is visible

  // Controllers for the forms
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  final _homeSizeController = TextEditingController();

  // --- Authentication Logic ---

  Future<void> _signInWithGoogle() async {
    try {
      // --- THIS IS THE CORRECTED LINE ---
      // We pass the clientId directly to the GoogleSignIn constructor.
      final googleUser = await GoogleSignIn(
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      ).signIn();

      if (googleUser == null) return; // User cancelled the flow

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _verifyAndCheckProfile(userCredential.user);
    } catch (e) {
      _showError("Google Sign-In failed: $e");
    }
  }

  // NOTE: You will need to enable Email/Password sign-up in Firebase Auth for this to work.
  Future<void> _signUpWithEmail() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _verifyAndCheckProfile(userCredential.user);
    } catch (e) {
      _showError("Sign-up failed: $e");
    }
  }

  // --- Backend and Database Logic ---

  Future<void> _verifyAndCheckProfile(User? user) async {
    if (user == null) return;

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('https://veridian-api-1jzx.onrender.com/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      _showError("Backend token verification failed. Status: ${response.statusCode}");
      return;
    }

    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      setState(() {
        _showProfileForm = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'email': user.email,
      'location': _locationController.text,
      'home_size_sqft': int.tryParse(_homeSizeController.text) ?? 0,
      'family_size': 0,
      'annual_income': 0,
      'monthly_energy_bill': 0,
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Veridian')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _showProfileForm ? _buildProfileForm() : _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 10),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _signUpWithEmail, child: const Text('Sign Up with Email')),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _signInWithGoogle, child: const Text('Sign in with Google')),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Complete Your Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location (e.g., CA, 90210)')),
        const SizedBox(height: 10),
        TextField(controller: _homeSizeController, decoration: const InputDecoration(labelText: 'Home Size (sqft)'), keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
      ],
    );
  }
}