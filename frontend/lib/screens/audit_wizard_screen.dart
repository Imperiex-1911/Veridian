// lib/screens/audit_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart'; // 1. IMPORT THE HOME SCREEN

class AuditWizardScreen extends StatefulWidget {
  const AuditWizardScreen({super.key});

  @override
  State<AuditWizardScreen> createState() => _AuditWizardScreenState();
}

class _AuditWizardScreenState extends State<AuditWizardScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = false; // 2. ADD LOADING STATE

  Future<void> _submitAudit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('audits').add({
        'user_id': user.uid,
        'answers': _answers,
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        // 3. USE ROBUST NAVIGATION
        // This clears the old screens and navigates to a fresh HomeScreen.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>  HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save audit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _showHeatingQuestion => _answers['insulation'] == 'poor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self-Audit Wizard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _submitAudit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          _buildStep1Appliances(),
          _buildStep2Insulation(),
          _buildStep3Windows(),
          _buildStep4Heating(),
          _buildStep5Summary(),
        ],
      ),
    );
  }

  // --- Helper methods to build each step ---
  // (These methods _buildStep1Appliances, etc., are unchanged)
  Step _buildStep1Appliances() {
    return Step(
      title: const Text('Step 1: Appliances'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How old is your primary refrigerator?'),
          RadioListTile<String>(
            title: const Text('< 5 years'),
            value: 'new',
            groupValue: _answers['fridge_age'],
            onChanged: (value) => setState(() => _answers['fridge_age'] = value),
          ),
          RadioListTile<String>(
            title: const Text('5 - 15 years'),
            value: 'medium',
            groupValue: _answers['fridge_age'],
            onChanged: (value) => setState(() => _answers['fridge_age'] = value),
          ),
          RadioListTile<String>(
            title: const Text('> 15 years'),
            value: 'old',
            groupValue: _answers['fridge_age'],
            onChanged: (value) => setState(() => _answers['fridge_age'] = value),
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildStep2Insulation() {
    return Step(
      title: const Text('Step 2: Insulation'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How would you rate your home\'s insulation?'),
          RadioListTile<String>(
            title: const Text('Good'),
            value: 'good',
            groupValue: _answers['insulation'],
            onChanged: (value) => setState(() => _answers['insulation'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Average'),
            value: 'average',
            groupValue: _answers['insulation'],
            onChanged: (value) => setState(() => _answers['insulation'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Poor'),
            value: 'poor',
            groupValue: _answers['insulation'],
            onChanged: (value) => setState(() => _answers['insulation'] = value),
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildStep3Windows() {
    return Step(
      title: const Text('Step 3: Windows'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What type of windows do you have?'),
          RadioListTile<String>(
            title: const Text('Single-pane'),
            value: 'single',
            groupValue: _answers['windows'],
            onChanged: (value) => setState(() => _answers['windows'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Double-pane'),
            value: 'double',
            groupValue: _answers['windows'],
            onChanged: (value) => setState(() => _answers['windows'] = value),
          ),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildStep4Heating() {
    return Step(
      title: const Text('Step 4: Heating/Cooling'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showHeatingQuestion)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your insulation is poor. How efficient is your heating system?'),
                Slider(
                  value: (_answers['heating_efficiency'] ?? 50.0).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: (_answers['heating_efficiency'] ?? 50.0).toInt().toString(),
                  onChanged: (value) => setState(() => _answers['heating_efficiency'] = value),
                ),
              ],
            )
          else
            const Text('Your insulation rating is good enough that we don\'t need more heating details.'),
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }

  Step _buildStep5Summary() {
    return Step(
      title: const Text('Step 5: Summary'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please review your answers before submitting:'),
          const SizedBox(height: 10),
          Text(_answers.toString()),
        ],
      ),
      isActive: _currentStep >= 4,
    );
  }
}