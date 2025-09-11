// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'rebates_screen.dart';
import 'audit_wizard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // The list of screens controlled by the BottomNavigationBar
  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    RebatesScreen(),
    AuditWizardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // The function to handle signing out
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // The AuthWrapper will automatically navigate to the LoginScreen.
  }

  @override
  Widget build(BuildContext context) {
    // A list of titles corresponding to each screen for the AppBar
    const List<String> _titles = ['Dashboard', 'Rebates', 'Self-Audit'];

    return Scaffold(
      // 1. APPBAR ADDED
      appBar: AppBar(
        // 2. DYNAMIC TITLE
        title: Text(_titles[_selectedIndex]),
        // 3. LOGOUT BUTTON ADDED
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard', // Changed from 'Home' for consistency
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Rebates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Audit',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}