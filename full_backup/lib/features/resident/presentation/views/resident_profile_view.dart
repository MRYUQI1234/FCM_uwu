import 'package:flutter/material.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';

// ═══════════════════════════════════════════════════════════
// Resident Profile — Reuses Admin ProfileView with resident data
// ═══════════════════════════════════════════════════════════

class ResidentProfileView extends StatefulWidget {
  final String displayUser;
  final bool isDark;

  const ResidentProfileView({
    super.key,
    required this.displayUser,
    required this.isDark,
  });

  @override
  State<ResidentProfileView> createState() => _ResidentProfileViewState();
}

class _ResidentProfileViewState extends State<ResidentProfileView> {
  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _name = widget.displayUser;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success'] && mounted) {
      final data = result['data'];
      final apiName = (data['name'] ?? '').toString();
      final apiEmail = (data['email'] ?? '').toString();
      final apiPhone = (data['phone'] ?? '').toString();

      // Filter out admin/technician data — this is a resident dashboard
      final nameIsAdmin = apiName.isEmpty ||
          apiName.toLowerCase().contains('admin') ||
          apiName.toLowerCase().contains('technician');
      final emailIsAdmin = apiEmail.isEmpty ||
          apiEmail.toLowerCase().contains('admin');

      setState(() {
        _name = nameIsAdmin ? 'Somchai Rakdee' : apiName;
        _email = emailIsAdmin ? 'somchai.r@gmail.com' : apiEmail;
        _phone = apiPhone.isNotEmpty ? apiPhone : '+66 81 234 5678';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileView(
      name: _name.isNotEmpty ? _name : 'Somchai Rakdee',
      email: _email.isNotEmpty ? _email : 'somchai.r@gmail.com',
      phone: _phone.isNotEmpty ? _phone : '+66 81 234 5678',
      role: 'Resident',
      imagePath: 'assets/resident_profile.png',
    );
  }
}
