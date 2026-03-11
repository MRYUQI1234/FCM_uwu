import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Admin (FE-09, FE-10)
    final allRequests = [
      {'id': 'REQ001', 'resident': 'John Doe', 'type': 'Electrical', 'status': 'Pending'},
      {'id': 'REQ002', 'resident': 'Jane Smith', 'type': 'Plumbing', 'status': 'In Progress'},
      {'id': 'REQ003', 'resident': 'Bob Wilson', 'type': 'Other', 'status': 'Completed'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar for Desktop View
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (int index) {},
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Requests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Technicians'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allRequests.length,
              itemBuilder: (context, index) {
                final req = allRequests[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(req['id']!.substring(3))),
                    title: Text('${req['type']} - ${req['resident']}'),
                    subtitle: Text('Status: ${req['status']}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'assign', child: Text('Assign Technician')),
                        const PopupMenuItem(value: 'view', child: Text('View Report (FE-10)')),
                        const PopupMenuItem(value: 'reject', child: Text('Reject Request')),
                      ],
                      onSelected: (value) {
                         if (value == 'view') {
                            Navigator.pushNamed(context, '/repor_view');
                         }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
