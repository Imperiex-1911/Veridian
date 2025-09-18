// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../widgets/recommendation_card.dart';

// --- SERVICE: Handles all data fetching for the dashboard ---
class DashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://veridian-api-1jzx.onrender.com';

  Future<DashboardData> fetchDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    // Sequentially fetch data needed for subsequent API calls
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception("User profile not found.");
    final profile = userDoc.data()!;

    final auditSnapshot = await _firestore.collection('audits').where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true).limit(1).get();
    if (auditSnapshot.docs.isEmpty) throw Exception("No audit found. Please complete a self-audit.");
    final auditAnswers = AuditAnswers.fromMap(auditSnapshot.docs.first.data()['answers'] as Map<String, dynamic>);

    // Fetch remaining data in parallel for maximum efficiency
    final results = await Future.wait([
      _fetchEmissions(user.uid, auditAnswers),
      _fetchRebates(profile),
      _fetchContractors(profile, auditAnswers),
    ]);

    return DashboardData(
      auditAnswers: auditAnswers,
      emissions: results[0] as Emissions,
      rebates: results[1] as List<Rebate>,
      contractors: results[2] as List<Contractor>,
    );
  }

  Future<Emissions> _fetchEmissions(String userId, AuditAnswers answers) async {
    final idToken = await _auth.currentUser!.getIdToken();
    final response = await http.post(Uri.parse('$_baseUrl/carbon/calculate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode({'user_id': userId, 'answers': answers.toMap()}));
    if (response.statusCode == 200) return Emissions.fromJson(jsonDecode(response.body)['emissions']);
    throw Exception('Failed to fetch emissions: ${response.body}');
  }

  Future<List<Rebate>> _fetchRebates(Map<String, dynamic> profile) async {
    final idToken = await _auth.currentUser!.getIdToken();
    final response = await http.post(Uri.parse('$_baseUrl/rebates/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode({'location': profile['location'], 'income': profile['annual_income']}));
    if (response.statusCode == 200) {
      final List<dynamic> rebateList = jsonDecode(response.body)['rebates'];
      return rebateList.map((json) => Rebate.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch rebates');
  }

  Future<List<Contractor>> _fetchContractors(Map<String, dynamic> profile, AuditAnswers answers) async {
    List<String> neededServices = [];
    if (answers.insulation == 'poor') neededServices.add('insulation');
    if (answers.windowType == 'single') neededServices.add('windows');
    if (answers.hvacAge == 'old') neededServices.add('heating_cooling');
    if (!answers.hasSolar) neededServices.add('solar');
    if (neededServices.isEmpty) return [];

    final idToken = await _auth.currentUser!.getIdToken();
    final response = await http.post(Uri.parse('$_baseUrl/contractors/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $idToken'},
        body: jsonEncode({'location': profile['location'], 'services': neededServices}));
    if (response.statusCode == 200) {
      final List<dynamic> contractorList = jsonDecode(response.body)['contractors'];
      return contractorList.map((json) => Contractor.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch contractors');
  }
}

// --- ENGINE: Contains the business logic for generating recommendations ---
class RecommendationEngine {
  List<Recommendation> generate(DashboardData data) {
    final recommendations = <Recommendation>[];
    if (data.auditAnswers.insulation == 'poor') {
      recommendations.add(Recommendation(
          title: 'Upgrade Your Insulation', reason: 'Poor insulation is a major source of energy loss for heating and cooling.',
          icon: Icons.shield_outlined,
          relevantRebate: data.rebates.where((r) => r.description.toLowerCase().contains('insulation')).firstOrNull,
          relevantContractor: data.contractors.where((c) => c.services.contains('insulation')).firstOrNull));
    }
    if (data.auditAnswers.hvacAge == 'old') {
      recommendations.add(Recommendation(
          title: 'Replace Your HVAC System', reason: 'Systems older than 15 years are significantly less efficient.',
          icon: Icons.ac_unit,
          relevantRebate: data.rebates.where((r) => r.description.toLowerCase().contains('heating')).firstOrNull,
          relevantContractor: data.contractors.where((c) => c.services.contains('heating_cooling')).firstOrNull));
    }
    if (!data.auditAnswers.hasSolar) {
      recommendations.add(Recommendation(
          title: 'Install Solar Panels', reason: 'Generate your own clean energy and reduce or eliminate electricity bills.',
          icon: Icons.solar_power_outlined,
          relevantRebate: data.rebates.where((r) => r.description.toLowerCase().contains('solar')).firstOrNull,
          relevantContractor: data.contractors.where((c) => c.services.contains('solar')).firstOrNull));
    }
    if (recommendations.isEmpty) {
      recommendations.add(Recommendation(title: "You're an Energy Star!", reason: "Your audit didn't flag any major issues. Keep up the great work!", icon: Icons.star_border));
    }
    return recommendations;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData>? _dataFuture;
  final DashboardService _service = DashboardService();
  final RecommendationEngine _engine = RecommendationEngine();

  @override
  void initState() {
    super.initState();
    _dataFuture = _service.fetchDashboardData();
  }

  void _refreshData() {
    setState(() { _dataFuture = _service.fetchDashboardData(); });
  }

  List<PieChartSectionData> _createChartSections(Emissions emissions) {
    final data = [
      {'category': 'Appliances', 'value': emissions.appliances, 'color': Colors.blueAccent},
      {'category': 'Heating/Cooling', 'value': emissions.heatingCooling, 'color': Colors.redAccent},
      {'category': 'Water Heater', 'value': emissions.waterHeater, 'color': Colors.orangeAccent},
      {'category': 'Windows', 'value': emissions.windows, 'color': Colors.purpleAccent},
    ];
    return data.where((d) => d['value'] as double > 0).map((item) {
      final value = item['value'] as double; final color = item['color'] as Color;
      return PieChartSectionData(value: value, title: '${value.toInt()}', color: color, radius: 80, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<DashboardData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text('An error occurred:\n${snapshot.error}', textAlign: TextAlign.center)));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Complete an audit to see your report.'));
            }

            final dashboardData = snapshot.data!;
            final recommendations = _engine.generate(dashboardData);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Carbon Footprint', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Estimated total: ${dashboardData.emissions.total.toInt()} kg CO2e/year', style: Theme.of(context).textTheme.titleMedium),
                  if (dashboardData.emissions.solar < 0) Text('Solar Credit: ${dashboardData.emissions.solar.toInt()} kg CO2e/year', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(height: 250, child: PieChart(PieChartData(sections: _createChartSections(dashboardData.emissions), centerSpaceRadius: 40, sectionsSpace: 2))),
                  const SizedBox(height: 24),
                  Text('Top Recommendations', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  ListView.builder(
                    itemCount: recommendations.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return RecommendationCard(recommendation: recommendations[index]);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}