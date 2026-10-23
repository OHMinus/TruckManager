import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared/capsules.dart' as model; // ご指定の通りエイリアスを追加
import '../services/firestore_service.dart';

class DetailPage extends StatelessWidget {
  final String id;
  final FirestoreService _firestoreService = FirestoreService();

  DetailPage({super.key, required this.id});

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri? url = Uri.tryParse(urlString);
    if (url != null) {
      if (!await launchUrl(url)) {
        debugPrint('Could not launch $urlString');
      }
    }
  }

  // 憶測: プログレスバーの進捗度を予約済み〜支払済みの順序で進行すると仮定しています
  double _getStateProgress(model.State state) {
    switch (state) {
      case model.State.unknown:
        return 0.0;
      case model.State.reserved:
        return 0.25;
      case model.State.outset:
        return 0.50;
      case model.State.unpaid:
        return 0.75;
      case model.State.paid:
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getCarImageUrl(String carType) {
    if (carType.contains('アルミトラック')) {
      return 'https://example.com/alumi_truck_sample.jpg';
    } else if (carType.contains('平トラック')) {
      return 'https://example.com/flat_truck_sample.jpg';
    } else if (carType.contains('バン')) {
      return 'https://example.com/van_sample.jpg';
    }
    return 'https://example.com/default_car.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchOrderAndRawData(id),
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

          final model.OrderCapsule order = snapshot.data!['capsule'];
          final Map<String, dynamic> rawData = snapshot.data!['raw'];

          final String? carType = rawData['carType']?.toString();
          final String carImageUrl = carType != null ? _getCarImageUrl(carType) : '';
          final bool isSemiMedium = carType != null && carType.contains('2t');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (carImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.network(
                      carImageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(child: Icon(Icons.directions_car, size: 100, color: Colors.grey)),
                          ),
                    ),
                  )
                else
                  const Card(
                    child: SizedBox(
                      height: 150,
                      child: Center(child: Icon(Icons.directions_car, size: 80, color: Colors.grey)),
                    ),
                  ),
                
                if (isSemiMedium)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'これは準中型免許が必要です',
                              style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),

                // StateJpを使用して日本語のステータスを表示
                Text(
                  'Status: ${model.StateJp[order.state] ?? "不明"}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: LinearProgressIndicator(
                    value: _getStateProgress(order.state),
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        _buildListTile(Icons.tag, 'ID', order.id),
                        _buildListTile(Icons.event, 'Event Name', order.objectName),
                        _buildListTile(Icons.calendar_today, 'Date', order.date),
                        _buildListTile(Icons.attach_money, 'Price', order.price),
                        _buildListTile(Icons.percent, 'Percentage', order.percentage),
                        _buildListTile(Icons.person, 'Reserver', order.reserver),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Additional Details (Raw Data)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        ...rawData.entries.map((entry) {
                          return _buildRawDataRow(entry.key, entry.value.toString());
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchOrderAndRawData(String id) async {
    final rawData =  await _firestoreService.getOrderById(id);
    if (rawData == null) throw Exception("Order not found");
    final capsule = model.OrderCapsule.fromJson(rawData);

    return {
      'capsule': capsule,
      'raw': rawData,
    };
  }

  Widget _buildListTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-', style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataRow(String label, String value) {
    final bool isUrl = value.startsWith('http://') || value.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            child: isUrl
                ? InkWell(
                    onTap: () => _launchUrl(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(value.isNotEmpty ? value : '-', style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}