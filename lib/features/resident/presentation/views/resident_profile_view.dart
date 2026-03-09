import 'package:flutter/material.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';

// ═══════════════════════════════════════════════════════════
// Resident Profile — Reuses Admin ProfileView with resident data
// ═══════════════════════════════════════════════════════════

class ResidentProfileView extends StatefulWidget {
  final String displayUser;
  final bool isDark;
  final VoidCallback? onMenuTap;

  const ResidentProfileView({
    super.key,
    required this.displayUser,
    required this.isDark,
    this.onMenuTap,
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
      setState(() {
        _name = (data['name'] ?? '').toString();
        _email = (data['email'] ?? '').toString();
        _phone = (data['phone'] ?? '').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileView(
      name: _name,
      email: _email,
      phone: _phone,
      role: 'Resident',
      imagePath: 'assets/resident_profile.png',
      onMenuTap: widget.onMenuTap,
    );
  }
}
