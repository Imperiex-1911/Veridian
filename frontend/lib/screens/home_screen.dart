// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'rebates_screen.dart';
import 'audit_wizard_screen.dart';
import 'contractors_screen.dart';
import 'chat_screen.dart'; // 1. Import the new chat screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 2. Add the ChatScreen to the list of navigable screens
  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    RebatesScreen(),
    AuditWizardScreen(),
    ContractorsScreen(),
    ChatScreen(), // New screen added here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Add "AI Advisor" to the list of titles for the AppBar
    const List<String> _titles = ['Dashboard', 'Rebates', 'Self-Audit', 'Contractors', 'AI Advisor'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // The 'fixed' type is essential for 4 or more items
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Rebates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Audit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            label: 'Contractors',
          ),
          // 4. Add the new navigation item for the AI Advisor
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Advisor',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}