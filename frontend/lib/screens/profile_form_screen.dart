// lib/screens/profile_form_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the HomeScreen for navigation

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _locationController = TextEditingController();
  final _homeSizeController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _incomeController = TextEditingController();
  final _energyBillController = TextEditingController();

  // State variable to show a loading spinner
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    // 1. Validation
    if (_locationController.text.isEmpty || _homeSizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 2. Save data with error handling
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'location': _locationController.text.trim(),
        'home_size_sqft': int.tryParse(_homeSizeController.text) ?? 0,
        'family_size': int.tryParse(_familySizeController.text) ?? 0,
        'annual_income': double.tryParse(_incomeController.text) ?? 0,
        'monthly_energy_bill': double.tryParse(_energyBillController.text) ?? 0,
      });

      // 3. Navigate to the dashboard on success
      if (mounted) {
        // This clears the navigation history so the user can't go back to the profile/login screens.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>  HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Center(
        // Show a loading spinner while saving
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location (e.g., CA, 90210)')),
              TextField(controller: _homeSizeController, decoration: const InputDecoration(labelText: 'Home Size (sqft)'), keyboardType: TextInputType.number),
              TextField(controller: _familySizeController, decoration: const InputDecoration(labelText: 'Family Size'), keyboardType: TextInputType.number),
              TextField(controller: _incomeController, decoration: const InputDecoration(labelText: 'Annual Income'), keyboardType: TextInputType.number),
              TextField(controller: _energyBillController, decoration: const InputDecoration(labelText: 'Monthly Energy Bill'), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}