// lib/screens/rebates_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. DATA MODEL for type-safety and cleaner code
class Rebate {
  final String id;
  final String name;
  final String description;
  final int amount;
  final String location;
  final int incomeMax;

  Rebate({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.location,
    required this.incomeMax,
  });

  factory Rebate.fromJson(Map<String, dynamic> json) {
    return Rebate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      amount: json['amount'] ?? 0,
      location: json['location'],
      incomeMax: json['income_max'] ?? 0,
    );
  }
}

class RebatesScreen extends StatefulWidget {
  const RebatesScreen({super.key});

  @override
  _RebatesScreenState createState() => _RebatesScreenState();
}

class _RebatesScreenState extends State<RebatesScreen> {
  // Use the Rebate model for our state list
  List<Rebate> _rebates = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRebates();
  }

  Future<void> _fetchRebates() async {
    // Show loading indicator on refresh
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "You must be logged in to see rebates.";
        _isLoading = false;
      });
      return;
    }

    try {
      // Get user profile from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw 'Please complete your profile to see eligible rebates.';
      }

      final profile = doc.data()!;
      final location = profile['location'] as String?;
      final income = profile['annual_income'] as num?;

      // 2. HANDLE INCOMPLETE PROFILE
      if (location == null || location.isEmpty) {
        throw 'Please set your location in your profile to find rebates.';
      }

      // 3. ADD AUTH TOKEN TO HEADER for security
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('https://veridian-api-1jzx.onrender.com/rebates'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // Add the token here
        },
        body: jsonEncode({
          'location': location,
          'income': income ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rebateList = data['rebates'];

        if (mounted) {
          setState(() {
            _rebates = rebateList.map((json) => Rebate.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        throw 'Failed to fetch rebates: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rebates')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_rebates.isEmpty) {
      return const Center(child: Text('No rebates are currently available for your profile.'));
    }

    // 4. ADD PULL-TO-REFRESH
    return RefreshIndicator(
      onRefresh: _fetchRebates,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _rebates.length,
        itemBuilder: (context, index) {
          final rebate = _rebates[index];
          // 5. IMPROVED UI CARD
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rebate.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Up to \$${rebate.amount}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rebate.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}