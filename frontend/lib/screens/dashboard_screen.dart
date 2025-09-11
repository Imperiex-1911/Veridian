import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _latestAudit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestAudit();
  }

  Future<void> _fetchLatestAudit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('audits')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _latestAudit = snapshot.docs.first.data()['answers'] as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching audit: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _generateRecommendations(Map<String, dynamic> answers) {
    List<String> recommendations = [];
    if (answers['fridge_age'] == '>15') {
      recommendations.add('Replace refrigerator (>15 years old) with an energy-efficient model.');
    }
    if (answers['insulation'] == 'poor') {
      recommendations.add('Upgrade insulation to reduce energy loss.');
    }
    if (answers['windows_single'] == true) {
      recommendations.add('Replace single-pane windows with double-pane for better efficiency.');
    }
    if ((answers['heating_efficiency'] ?? 100) < 70) {
      recommendations.add('Service or replace heating system (efficiency <70%).');
    }
    if (answers['led_lighting'] != true) {
      recommendations.add('Switch to LED lighting for energy savings.');
    }
    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestAudit == null
          ? const Center(child: Text('No audits completed yet'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Improvement Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._generateRecommendations(_latestAudit!).map((rec) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(rec),
            )),
            const SizedBox(height: 16),
            const Text('Placeholder: Carbon Footprint Pie Chart'),
            // Add charts_flutter pie chart in Day 10
          ],
        ),
      ),
    );
  }
}