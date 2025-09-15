// lib/screens/audit_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

// 1. TYPED MODEL CLASS instead of a Map
class AuditAnswers {
  String? fridgeAge;
  bool hasDryer = false;
  bool hasDishwasher = false;
  String? insulation;
  String? windowType;
  String? hvacAge;
  String? waterHeater;
  bool? hasSolar;

  // Method to convert the object to a Map for Firestore
  Map<String, dynamic> toMap() => {
    'fridge_age': fridgeAge,
    'has_dryer': hasDryer,
    'has_dishwasher': hasDishwasher,
    'insulation': insulation,
    'window_type': windowType,
    'hvac_age': hvacAge,
    'water_heater': waterHeater,
    'has_solar': hasSolar,
  };
}

class AuditWizardScreen extends StatefulWidget {
  const AuditWizardScreen({super.key});
  @override
  _AuditWizardScreenState createState() => _AuditWizardScreenState();
}

class _AuditWizardScreenState extends State<AuditWizardScreen> {
  int _currentStep = 0;
  // Use the new typed model for state
  final AuditAnswers _answers = AuditAnswers();
  bool _isLoading = false;

  Future<void> _submitAudit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('audits').add({
        'user_id': user.uid,
        'answers': _answers.toMap(), // Use the toMap() method here
        'timestamp': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit saved successfully!')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving audit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Validation now checks the typed model properties
  bool _validateStep(int step) {
    switch (step) {
      case 0: return _answers.fridgeAge != null;
      case 1: return _answers.insulation != null;
      case 2: return _answers.windowType != null;
      case 3: return _answers.hvacAge != null;
      case 4: return _answers.waterHeater != null && _answers.hasSolar != null;
      default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. DYNAMIC STEP HANDLING
    // Define the list of steps here to easily get the length
    final steps = [
      _buildStep1Appliances(),
      _buildStep2Insulation(),
      _buildStep3Windows(),
      _buildStep4Heating(),
      _buildStep5Miscellaneous(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Self-Audit Wizard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
        currentStep: _currentStep,
        steps: steps, // Use the dynamically created list
        onStepContinue: () {
          if (_validateStep(_currentStep)) {
            // Use steps.length instead of a hardcoded number
            if (_currentStep < steps.length - 1) {
              setState(() => _currentStep++);
            } else {
              _submitAudit();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please answer all questions to continue.'),
                backgroundColor: Colors.red));
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (details.currentStep > 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  // Check against steps.length here too
                  child: Text(details.currentStep == steps.length - 1 ? 'Submit' : 'Next'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS FOR EACH STEP (NOW UPDATED) ---

  Step _buildStep1Appliances() {
    return Step(
      title: const Text('Step 1: Appliances'),
      // 3. RESPONSIVE LAYOUT with SingleChildScrollView
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How old is your primary refrigerator?'),
            RadioListTile<String>(title: const Text('< 5 years'), value: 'new', groupValue: _answers.fridgeAge, onChanged: (v) => setState(() => _answers.fridgeAge = v)),
            RadioListTile<String>(title: const Text('5 - 15 years'), value: 'medium', groupValue: _answers.fridgeAge, onChanged: (v) => setState(() => _answers.fridgeAge = v)),
            RadioListTile<String>(title: const Text('> 15 years'), value: 'old', groupValue: _answers.fridgeAge, onChanged: (v) => setState(() => _answers.fridgeAge = v)),
            const Divider(height: 24),
            const Text('Which of these do you own and use regularly?'),
            CheckboxListTile(title: const Text('Electric Clothes Dryer'), value: _answers.hasDryer, onChanged: (v) => setState(() => _answers.hasDryer = v ?? false)),
            CheckboxListTile(title: const Text('Dishwasher'), value: _answers.hasDishwasher, onChanged: (v) => setState(() => _answers.hasDishwasher = v ?? false)),
          ],
        ),
      ),
      isActive: _currentStep >= 0,
    );
  }

  Step _buildStep2Insulation() {
    return Step(
      title: const Text('Step 2: Insulation'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is the quality of your home insulation?'),
            RadioListTile<String>(title: const Text('Good'), value: 'good', groupValue: _answers.insulation, onChanged: (v) => setState(() => _answers.insulation = v)),
            RadioListTile<String>(title: const Text('Average'), value: 'average', groupValue: _answers.insulation, onChanged: (v) => setState(() => _answers.insulation = v)),
            RadioListTile<String>(title: const Text('Poor'), value: 'poor', groupValue: _answers.insulation, onChanged: (v) => setState(() => _answers.insulation = v)),
          ],
        ),
      ),
      isActive: _currentStep >= 1,
    );
  }

  Step _buildStep3Windows() {
    return Step(
      title: const Text('Step 3: Windows'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What type of windows do you have?'),
            RadioListTile<String>(title: const Text('Single-pane'), value: 'single', groupValue: _answers.windowType, onChanged: (v) => setState(() => _answers.windowType = v)),
            RadioListTile<String>(title: const Text('Double-pane'), value: 'double', groupValue: _answers.windowType, onChanged: (v) => setState(() => _answers.windowType = v)),
          ],
        ),
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildStep4Heating() {
    return Step(
      title: const Text('Step 4: Heating & Cooling'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How old is your primary heating/cooling (HVAC) system?'),
            RadioListTile<String>(title: const Text('< 5 years'), value: 'new', groupValue: _answers.hvacAge, onChanged: (v) => setState(() => _answers.hvacAge = v)),
            RadioListTile<String>(title: const Text('5 - 15 years'), value: 'medium', groupValue: _answers.hvacAge, onChanged: (v) => setState(() => _answers.hvacAge = v)),
            RadioListTile<String>(title: const Text('> 15 years'), value: 'old', groupValue: _answers.hvacAge, onChanged: (v) => setState(() => _answers.hvacAge = v)),
          ],
        ),
      ),
      isActive: _currentStep >= 3,
    );
  }

  Step _buildStep5Miscellaneous() {
    return Step(
      title: const Text('Step 5: Miscellaneous'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What type of water heater do you have?'),
            RadioListTile<String>(title: const Text('Electric Storage'), value: 'electric_storage', groupValue: _answers.waterHeater, onChanged: (v) => setState(() => _answers.waterHeater = v)),
            RadioListTile<String>(title: const Text('Gas Storage'), value: 'gas_storage', groupValue: _answers.waterHeater, onChanged: (v) => setState(() => _answers.waterHeater = v)),
            RadioListTile<String>(title: const Text('Heat Pump'), value: 'heat_pump_wh', groupValue: _answers.waterHeater, onChanged: (v) => setState(() => _answers.waterHeater = v)),
            const Divider(height: 24),
            const Text('Do you have rooftop solar panels?'),
            RadioListTile<bool>(title: const Text('Yes'), value: true, groupValue: _answers.hasSolar, onChanged: (v) => setState(() => _answers.hasSolar = v)),
            RadioListTile<bool>(title: const Text('No'), value: false, groupValue: _answers.hasSolar, onChanged: (v) => setState(() => _answers.hasSolar = v)),
          ],
        ),
      ),
      isActive: _currentStep >= 4,
    );
  }
}