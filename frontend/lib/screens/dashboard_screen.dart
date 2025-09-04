// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // This is the query to get the latest audit for the logged-in user
    final auditQuery = FirebaseFirestore.instance
        .collection('audits')
        .where('user_id', isEqualTo: user?.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Eco-Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(), // Add a sign-out button
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Display the Latest Audit ---
          const Text('Your Latest Audit Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          FutureBuilder<QuerySnapshot>(
            future: auditQuery,
            builder: (context, snapshot) {
              // 1. While waiting for data, show a loading spinner
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // 2. If there's an error
              if (snapshot.hasError) {
                return Text('Error fetching audit: ${snapshot.error}');
              }
              // 3. If there is no data or no documents found
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('You have not completed an audit yet.');
              }
              // 4. If we have data, display it
              final latestAudit = snapshot.data!.docs.first;
              final answers = latestAudit['answers'] as Map<String, dynamic>;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(answers.toString()),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // --- Your other dashboard sections ---
          Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Carbon Footprint Pie Chart Placeholder'),
          ),
          const SizedBox(height: 16),
          const Text('Improvement Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          // ... other list tiles
        ],
      ),
    );
  }
}