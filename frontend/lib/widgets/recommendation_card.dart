// lib/widgets/recommendation_card.dart
import 'package:flutter/material.dart';
import '../models.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(recommendation.icon, color: Theme.of(context).primaryColor, size: 40),
              title: Text(recommendation.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(recommendation.reason),
            ),
            const Divider(height: 24),
            if (recommendation.relevantRebate != null)
              _buildLinkRow(
                icon: Icons.local_offer,
                label: 'REBATE:',
                text: '${recommendation.relevantRebate!.name} (\$${recommendation.relevantRebate!.amount.toInt()})',
              ),
            if (recommendation.relevantContractor != null)
              _buildLinkRow(
                icon: Icons.build,
                label: 'CONTRACTOR:',
                text: '${recommendation.relevantContractor!.name} (★ ${recommendation.relevantContractor!.rating})',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkRow({required IconData icon, required String label, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}