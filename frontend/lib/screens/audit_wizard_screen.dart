// lib/screens/audit_wizard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; // Import for navigation

class AuditWizardScreen extends StatefulWidget {
  const AuditWizardScreen({super.key});
  @override
  _AuditWizardScreenState createState() => _AuditWizardScreenState();
}

class _AuditWizardScreenState extends State<AuditWizardScreen> {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  bool _isLoading = false;

  // Conditional logic for Step 4
  bool get _showHeatingQuestions =>
      _answers['insulation'] == 'poor' || _answers['insulation'] == 'average';

  Future<void> _submitAudit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('audits').add({
        'user_id': user.uid,
        'answers': _answers,
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audit saved successfully!')));
        // Use robust navigation to a fresh HomeScreen instance
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
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

  // --- Input Validation Logic ---
  bool _validateStep(int step) {
    switch (step) {
      case 0:
        return _answers.containsKey('fridge_age');
      case 1:
        return _answers.containsKey('insulation');
      case 2: // This is Step 3
      // --- THIS IS THE FIX ---
      // We now correctly check for the 'window_type' key.
        return _answers.containsKey('window_type');
      case 3:
        if (_showHeatingQuestions) {
          // This was missing validation, now added.
          return _answers.containsKey('heating_type');
        }
        return true; // No validation needed if questions are hidden
      case 4:
        return _answers.containsKey('water_heater');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Self-Audit Wizard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_validateStep(_currentStep)) {
            if (_currentStep < 4) {
              setState(() => _currentStep++);
            } else {
              _submitAudit();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please answer the question to continue.'),
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
                  child: Text(details.currentStep == 4 ? 'Submit' : 'Next'),
                ),
              ],
            ),
          );
        },
        steps: [
          _buildStep1Appliances(),
          _buildStep2Insulation(),
          _buildStep3Windows(),
          _buildStep4Heating(),
          _buildStep5Miscellaneous(),
        ],
      ),
    );
  }

  // --- WIDGETS FOR EACH STEP ---

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
          const Text('What is the quality of your home insulation?'),
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
            groupValue: _answers['window_type'],
            onChanged: (value) => setState(() => _answers['window_type'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Double-pane'),
            value: 'double',
            groupValue: _answers['window_type'],
            onChanged: (value) => setState(() => _answers['window_type'] = value),
          ),
        ],
      ),
      isActive: _currentStep >= 2,
    );
  }

  Step _buildStep4Heating() {
    return Step(
      title: const Text('Step 4: Heating & Cooling'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showHeatingQuestions) ...[
            const Text('What type of heating system do you use?'),
            RadioListTile<String>(
              title: const Text('Gas Furnace'),
              value: 'gas_furnace',
              groupValue: _answers['heating_type'],
              onChanged: (value) => setState(() => _answers['heating_type'] = value),
            ),
            RadioListTile<String>(
              title: const Text('Electric Heat Pump'),
              value: 'heat_pump',
              groupValue: _answers['heating_type'],
              onChanged: (value) => setState(() => _answers['heating_type'] = value),
            ),
            RadioListTile<String>(
              title: const Text('Other Electric'),
              value: 'electric_other',
              groupValue: _answers['heating_type'],
              onChanged: (value) => setState(() => _answers['heating_type'] = value),
            ),
          ] else
            const Text('Your insulation is good, so no extra heating questions are needed.'),
        ],
      ),
      isActive: _currentStep >= 3,
    );
  }

  Step _buildStep5Miscellaneous() {
    return Step(
      title: const Text('Step 5: Miscellaneous'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What type of water heater do you have?'),
          RadioListTile<String>(
            title: const Text('Electric Storage'),
            value: 'electric_storage',
            groupValue: _answers['water_heater'],
            onChanged: (value) => setState(() => _answers['water_heater'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Gas Storage'),
            value: 'gas_storage',
            groupValue: _answers['water_heater'],
            onChanged: (value) => setState(() => _answers['water_heater'] = value),
          ),
          RadioListTile<String>(
            title: const Text('Heat Pump'),
            value: 'heat_pump_wh',
            groupValue: _answers['water_heater'],
            onChanged: (value) => setState(() => _answers['water_heater'] = value),
          ),
        ],
      ),
      isActive: _currentStep >= 4,
    );
  }
}