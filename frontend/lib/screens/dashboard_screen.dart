import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Eco-Dashboard')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Pie chart placeholder
          Container(
            height: 200,
            alignment: Alignment.center,
            child: Text('Carbon Footprint Pie Chart Placeholder'),
          ),
          SizedBox(height: 16),
          Text('Improvement Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Column(
            children: [
              ListTile(title: Text('Upgrade insulation')),
              ListTile(title: Text('Replace old fridge')),
            ],
          ),
          SizedBox(height: 16),
          Text('Matching Rebates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Column(
            children: [
              Card(child: ListTile(title: Text('Solar Rebate: \$5000'))),
              Card(child: ListTile(title: Text('Insulation Credit: \$1200'))),
            ],
          ),
        ],
      ),
    );
  }
}