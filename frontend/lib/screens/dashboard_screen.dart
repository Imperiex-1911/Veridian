// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

// (Models are unchanged)
class AuditAnswers {
  final String fridgeAge; final String insulation; final String windowType;
  final String hvacAge; final bool hasSolar; final bool hasDryer;
  final bool hasDishwasher;
  AuditAnswers({ required this.fridgeAge, required this.insulation, required this.windowType, required this.hvacAge, required this.hasSolar, required this.hasDryer, required this.hasDishwasher });
  factory AuditAnswers.fromMap(Map<String, dynamic> map) {
    return AuditAnswers(fridgeAge: map['fridge_age'] ?? 'new', insulation: map['insulation'] ?? 'good', windowType: map['window_type'] ?? 'double', hvacAge: map['hvac_age'] ?? 'new', hasSolar: map['has_solar'] ?? false, hasDryer: map['has_dryer'] ?? false, hasDishwasher: map['has_dishwasher'] ?? false);
  }
  Map<String, dynamic> toMap() {
    return {'fridge_age': fridgeAge, 'insulation': insulation, 'window_type': windowType, 'hvac_age': hvacAge, 'has_solar': hasSolar, 'has_dryer': hasDryer, 'has_dishwasher': hasDishwasher};
  }
}
class Emissions {
  final double appliances; final double heatingCooling; final double waterHeater;
  final double windows; final double solar; final double total;
  Emissions({ required this.appliances, required this.heatingCooling, required this.waterHeater, required this.windows, required this.solar, required this.total });
  factory Emissions.fromJson(Map<String, dynamic> json) { return Emissions(appliances: (json['appliances'] ?? 0).toDouble(), heatingCooling: (json['heating_cooling'] ?? 0).toDouble(), waterHeater: (json['water_heater'] ?? 0).toDouble(), windows: (json['windows'] ?? 0).toDouble(), solar: (json['solar'] ?? 0).toDouble(), total: (json['total'] ?? 0).toDouble()); }
}


class DashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AuditAnswers?> fetchLatestAuditAnswers() async {
    final user = _auth.currentUser; if (user == null) return null;
    final snapshot = await _firestore.collection('audits').where('user_id', isEqualTo: user.uid).orderBy('timestamp', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data()['answers'] as Map<String, dynamic>;
    return AuditAnswers.fromMap(data);
  }

  // --- MODIFIED: fetchEmissions now takes both userId and answers ---
  Future<Emissions?> fetchEmissions(String userId, AuditAnswers answers) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('https://veridian-api-1jzx.onrender.com/carbon/calculate'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
      // --- MODIFIED: The body now contains BOTH the userId and the answers ---
      body: jsonEncode({
        'user_id': userId, // The missing field
        'answers': answers.toMap()
      }),
    );

    if (response.statusCode == 200) {
      return Emissions.fromJson(jsonDecode(response.body)['emissions']);
    }
    throw Exception('Failed to fetch emissions: ${response.body}');
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void>? _dataFuture;
  AuditAnswers? _auditAnswers;
  Emissions? _emissions;
  String? _errorMessage;
  final DashboardService _service = DashboardService();

  @override
  void initState() { super.initState(); _dataFuture = _fetchData(); }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _errorMessage = null; });
    try {
      final auditAnswers = await _service.fetchLatestAuditAnswers();
      if (auditAnswers == null) {
        if (mounted) setState(() { _auditAnswers = null; _emissions = null; });
        return;
      }

      // --- MODIFIED: Pass the user.uid to the service call ---
      final emissions = await _service.fetchEmissions(user.uid, auditAnswers);

      if (mounted) {
        setState(() {
          _auditAnswers = auditAnswers;
          _emissions = emissions;
        });
      }
    } catch (e) {
      if (mounted) { setState(() { _errorMessage = e.toString(); }); }
    }
  }

  // (The rest of the file is unchanged)
  List<String> _generateRecommendations(AuditAnswers answers) {
    List<String> recommendations = [];
    if (answers.fridgeAge == 'old') recommendations.add('Upgrade your old refrigerator to an energy-efficient model.');
    if (answers.insulation == 'poor') recommendations.add('Improve your home insulation to reduce heating and cooling costs.');
    if (answers.windowType == 'single') recommendations.add('Replace single-pane windows with double-pane to improve efficiency.');
    if (answers.hvacAge == 'old') recommendations.add('Your HVAC system is over 15 years old. Consider an upgrade to a modern, high-efficiency unit.');
    if (!answers.hasSolar) recommendations.add('Consider installing rooftop solar panels to drastically reduce your carbon footprint.');
    if (answers.hasDryer) recommendations.add('Use a clothesline instead of an electric dryer when possible to save energy.');
    if (recommendations.isEmpty) recommendations.add("You're doing great! No immediate high-priority recommendations.");
    return recommendations;
  }
  List<PieChartSectionData> _createChartSections(Emissions emissions) {
    final data = [{'category': 'Appliances', 'value': emissions.appliances, 'color': Colors.blue},{'category': 'Heating/Cooling', 'value': emissions.heatingCooling, 'color': Colors.red},{'category': 'Water Heater', 'value': emissions.waterHeater, 'color': Colors.orange},{'category': 'Windows', 'value': emissions.windows, 'color': Colors.purple},];
    return data.where((d) => d['value'] as double > 0).map((item) {
      final value = item['value'] as double; final color = item['color'] as Color;
      return PieChartSectionData(value: value, title: '${value.toInt()}', color: color, radius: 80, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }
  @override Widget build(BuildContext context) {
    return Scaffold(body: RefreshIndicator(onRefresh: _fetchData, child: FutureBuilder(future: _dataFuture, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
      if (_errorMessage != null) { return Center(child: Text('An error occurred: $_errorMessage')); }
      if (_auditAnswers == null) { return const Center(child: Text('Complete your first self-audit to see your report!')); }
      final emissions = _emissions!; final auditAnswers = _auditAnswers!;
      return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Carbon Footprint', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8), Text('Estimated total: ${emissions.total.toInt()} kg CO2e/year', style: Theme.of(context).textTheme.titleMedium),
        if (emissions.solar < 0) Text('Solar Credit: ${emissions.solar.toInt()} kg CO2e/year', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16), SizedBox(height: 250, child: PieChart(PieChartData(sections: _createChartSections(emissions), centerSpaceRadius: 40, sectionsSpace: 2))),
        const SizedBox(height: 24), Text('Improvement Report', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8), Column(children: _generateRecommendations(auditAnswers).map((rec) => ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: Text(rec))).toList()),
      ]));
    })));
  }
}