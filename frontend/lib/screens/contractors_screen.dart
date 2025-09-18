import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Contractor {
  final String id;
  final String name;
  final List<String> services;
  final String location;
  final String contact;
  final double rating;

  Contractor({
    required this.id,
    required this.name,
    required this.services,
    required this.location,
    required this.contact,
    required this.rating,
  });

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'],
      name: json['name'],
      services: json['services'] != null
          ? List<String>.from(json['services'])
          : [],
      location: json['location'] ?? 'Unknown',
      contact: json['contact'] ?? 'N/A',
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class ContractorService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Contractor>> fetchContractors() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw Exception("User profile not found.");
    final location = userDoc.data()?['location'];
    if (location == null) throw Exception("User location not set in profile.");

    final auditSnapshot = await _firestore
        .collection('audits')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (auditSnapshot.docs.isEmpty) return [];

    final answers =
    auditSnapshot.docs.first.data()['answers'] as Map<String, dynamic>;

    List<String> neededServices = [];
    if (answers['insulation'] == 'poor') neededServices.add('insulation');
    if (answers['window_type'] == 'single') neededServices.add('windows');
    if (answers['hvac_age'] == 'old') neededServices.add('heating_cooling');
    if (answers['has_solar'] != true) neededServices.add('solar');

    if (neededServices.isEmpty) return [];

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('https://veridian-api-1jzx.onrender.com/contractors/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'location': location,
        'services': neededServices,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> contractorList = data['contractors'];
      return contractorList.map((json) => Contractor.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch contractors: ${response.body}');
    }
  }
}

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key});
  @override
  _ContractorsScreenState createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> {
  Future<List<Contractor>>? _contractorsFuture;
  final ContractorService _service = ContractorService();

  @override
  void initState() {
    super.initState();
    _contractorsFuture = _service.fetchContractors();
  }

  void _refreshContractors() {
    setState(() {
      _contractorsFuture = _service.fetchContractors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Contractor>>(
        future: _contractorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No relevant contractors found based on your audit.'),
            );
          }

          final contractors = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              _refreshContractors();
              return;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: contractors.length,
              itemBuilder: (context, index) {
                final contractor = contractors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      contractor.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Services: ${contractor.services.join(', ')}'),
                        const SizedBox(height: 4),
                        Text('Contact: ${contractor.contact}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text('★ ${contractor.rating.toStringAsFixed(1)}'),
                      backgroundColor: Colors.amber[100],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
