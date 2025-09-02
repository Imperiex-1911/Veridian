import 'package:flutter/material.dart';

class AuditWizardScreen extends StatefulWidget {
  @override
  _AuditWizardScreenState createState() => _AuditWizardScreenState();
}

class _AuditWizardScreenState extends State<AuditWizardScreen> {
  int _currentStep = 0;
  String? _insulationQuality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Self-Audit Wizard')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _currentStep < 1 ? () => setState(() => _currentStep++) : null,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        controlsBuilder: (context, details) {
          return Row(
            children: [
              if (details.currentStep > 0)
                TextButton(onPressed: details.onStepCancel, child: Text('Back')),
              Spacer(),
              TextButton(onPressed: details.onStepContinue, child: Text('Next')),
            ],
          );
        },
        steps: [
          Step(
            title: Text('Step 1 of 5: Insulation'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What type of insulation do you have?'),
                RadioListTile(
                  title: Text('Good'),
                  value: 'good',
                  groupValue: _insulationQuality,
                  onChanged: (value) => setState(() => _insulationQuality = value as String),
                ),
                RadioListTile(
                  title: Text('Average'),
                  value: 'average',
                  groupValue: _insulationQuality,
                  onChanged: (value) => setState(() => _insulationQuality = value as String),
                ),
                RadioListTile(
                  title: Text('Poor'),
                  value: 'poor',
                  groupValue: _insulationQuality,
                  onChanged: (value) => setState(() => _insulationQuality = value as String),
                ),
              ],
            ),
          ),
          Step(
            title: Text('Step 2 of 5: Appliances'),
            content: Text('Placeholder: Appliance questions'),
          ),
        ],
      ),
    );
  }
}