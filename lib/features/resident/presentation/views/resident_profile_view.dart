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

  final String? pictureUri;

  const ResidentProfileView({
    super.key,
    required this.displayUser,
    required this.isDark,
    this.pictureUri,
    this.onMenuTap,
    this.onProfileUpdated,
  });

  final VoidCallback? onProfileUpdated;

  @override
  State<ResidentProfileView> createState() => _ResidentProfileViewState();
}

class _ResidentProfileViewState extends State<ResidentProfileView> {
  String _name = '';
  String _email = '';
  String _phone = '';
  String _imagePath = 'assets/resident_profile.png';

  @override
  void initState() {
    super.initState();
    _name = widget.displayUser;
    _imagePath = (widget.pictureUri != null && widget.pictureUri!.isNotEmpty)
        ? widget.pictureUri!
        : 'assets/resident_profile.png';
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
        final uri = data['picture_uri']?.toString();
        _imagePath = (uri != null && uri.isNotEmpty)
            ? uri
            : 'assets/resident_profile.png';
      });
      // Also notify parent
      widget.onProfileUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileView(
      name: _name,
      email: _email,
      phone: _phone,
      role: 'RESIDENT',
      imagePath: _imagePath,
      onMenuTap: widget.onMenuTap,
      onProfileUpdated: _loadProfile,
    );
  }
}
