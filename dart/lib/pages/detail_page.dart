import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/capsules.dart';
import '../services/firestore_service.dart';

class DetailPage extends StatelessWidget {
  final String id;
  final FirestoreService _firestoreService = FirestoreService();

  DetailPage({super.key, required this.id});

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<OrderCapsule?>(
        future: _firestoreService.getOrderById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Order not found'));
          }

          final order = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildInfoRow('ID', order.id),
                _buildInfoRow('Event Name', order.objectName),
                _buildInfoRow('Date', order.date),
                _buildInfoRow('Price', order.price),
                _buildInfoRow('Percentage', order.percentage),
                _buildInfoRow('State', order.state.name),
                _buildInfoRow('Reserver', order.reserver),
                if (order.lastUpdated != null)
                  _buildInfoRow('Last Updated', order.lastUpdated.toString()),
                const SizedBox(height: 24),
                if (order.url.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _launchUrl(order.url),
                    icon: const Icon(Icons.link),
                    label: const Text('Open URL'),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-'),
          ),
        ],
      ),
    );
  }
}
