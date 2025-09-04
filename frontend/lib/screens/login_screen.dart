// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'profile_form_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // State variable to show a loading spinner
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- Logic for an EXISTING user logging in ---
  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // On success, AuthWrapper handles navigation to the Dashboard.
    } on FirebaseAuthException catch (e) {
      _showError("Login failed: ${e.message}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic for a NEW user signing up ---
  Future<void> _signUpWithEmail() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // After creating the user, check their profile.
      await _verifyAndCheckProfile(userCredential.user);
    } on FirebaseAuthException catch (e) {
      _showError("Sign-up failed: ${e.message}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Logic for Google Sign-In (handles both new and existing users) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn(
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      ).signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return; // User cancelled the sign-in
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);

      // Crucially, check if this is the user's first time signing in
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _verifyAndCheckProfile(userCredential.user);
      }
      // If it's an existing user, the AuthWrapper will handle navigation automatically.

    } catch (e) {
      _showError("Google Sign-In failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // This function is now only called for NEW users to check for a profile
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
    if (!doc.exists && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ProfileFormScreen()),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Veridian')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // Show a loading spinner if _isLoading is true
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              // Separate buttons for Login and Sign Up
              ElevatedButton(
                onPressed: _signInWithEmail,
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _signUpWithEmail,
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.login), // Example of adding an icon
                onPressed: _signInWithGoogle,
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}