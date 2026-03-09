import 'package:flutter/material.dart';

class RepairListScreen extends StatelessWidget {
  const RepairListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final requests = [
      {'id': 'REQ001', 'type': 'Electrical', 'status': 'Pending', 'date': '2023-10-25'},
      {'id': 'REQ002', 'type': 'Plumbing', 'status': 'In Progress', 'date': '2023-10-20'},
      {'id': 'REQ003', 'type': 'Other', 'status': 'Completed', 'date': '2023-10-15'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Repair Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar),
            onPressed: () => Navigator.pushNamed(context, '/3d_model'),
            tooltip: 'View 3D House Model',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(_getIcon(req['type']!)),
              title: Text('${req['type']} (${req['id']})'),
              subtitle: Text('Date: ${req['date']}'),
              trailing: Chip(
                label: Text(req['status']!),
                backgroundColor: _getStatusColor(req['status']!),
              ),
              onTap: () {
                // Navigate to details or Assessment (FE-06) if completed
                if (req['status'] == 'Completed') {
                  // Show Assessment Dialog
                  _showAssessmentDialog(context);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_repair');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Electrical': return Icons.electrical_services;
      case 'Plumbing': return Icons.plumbing;
      default: return Icons.build;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange.shade100;
      case 'In Progress': return Colors.blue.shade100;
      case 'Completed': return Colors.green.shade100;
      default: return Colors.grey.shade100;
    }
  }

  void _showAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Satisfaction (FE-06)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was the service?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return const Icon(Icons.star_border, color: Colors.amber, size: 32);
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
