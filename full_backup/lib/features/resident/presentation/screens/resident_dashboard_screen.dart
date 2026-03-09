import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/hover_sidebar.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_home_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_repair_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_history_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_profile_view.dart';

// ─────────────────────────────────────────────────────────
// Zeta V5.0 — Resident Dashboard (Main Shell)
// Left sidebar auto-hides after 10s, reveal on hover
// ─────────────────────────────────────────────────────────

class ResidentDashboardScreen extends StatefulWidget {
  final String username;
  const ResidentDashboardScreen({super.key, this.username = 'Somchai Rakdee'});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _displayUsername = '';
  String _houseId = '123/45';

  // ── Sidebar auto-hide ──
  late AnimationController _sidebarAnim;
  Timer? _hideTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _displayUsername = widget.username;
    _fetchUserProfile();

    _sidebarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0, // starts visible
    );

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _sidebarAnim.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (!_isHovering && mounted) {
        _sidebarAnim.animateTo(0.0, curve: Curves.easeInOutCubic);
      }
    });
  }

  void _showSidebar() {
    _hideTimer?.cancel();
    if (mounted) {
      _sidebarAnim.animateTo(1.0, curve: Curves.easeOutCubic);
    }
  }

  void _onSidebarHoverEnter() {
    _isHovering = true;
    _showSidebar();
  }

  void _onSidebarHoverExit() {
    _isHovering = false;
    _startHideTimer();
  }

  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success']) {
      final data = result['data'];
      if (mounted) {
        setState(() {
          final apiName = data['name'] ?? '';
          // Use API name only if it looks like a real resident name
          final isGeneric = apiName.isEmpty ||
              apiName.toLowerCase().contains('admin') ||
              apiName.toLowerCase().contains('technician');
          _displayUsername = isGeneric ? 'Somchai Rakdee' : apiName;
          if (data['houseId'] != null) _houseId = data['houseId'];
        });
      }
    } else if (result['expired'] == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final displayUser = _displayUsername.isNotEmpty && _displayUsername != 'Somchai Rakdee'
        ? _displayUsername
        : (args is String ? args : widget.username);

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: DashboardTheme.background,
          body: Stack(
            children: [
              // ── Main layout: sidebar + content ──
              Row(
                children: [
                  // Animated sidebar (width collapses to 0)
                  AnimatedBuilder(
                    animation: _sidebarAnim,
                    builder: (context, child) {
                      final value = _sidebarAnim.value;
                      if (value == 0.0) return const SizedBox.shrink();
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: RepaintBoundary(
                      child: MouseRegion(
                        onEnter: (_) => _onSidebarHoverEnter(),
                        onExit: (_) => _onSidebarHoverExit(),
                        child: HoverSidebar(
                          selectedIndex: _currentIndex,
                          onIndexChanged: (i) {
                            setState(() => _currentIndex = i);
                            _startHideTimer();
                          },
                          onLogout: () => _showLogoutConfirmation(context),
                          brandTitle: 'ZETA ESTATE',
                          brandSubtitle: 'RESIDENT PORTAL',
                          items: const [
                            SidebarItem(index: 0, icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
                            SidebarItem(index: 1, icon: Icons.build_rounded, label: 'REPAIR'),
                            SidebarItem(index: 2, icon: Icons.history_rounded, label: 'HISTORY'),
                            SidebarItem(index: 3, icon: Icons.person_rounded, label: 'PROFILE'),
                            SidebarItem(index: 4, icon: Icons.settings_rounded, label: 'SETTINGS'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content fills remaining space
                  Expanded(
                    child: RepaintBoundary(
                      child: _buildView(index: _currentIndex, displayUser: displayUser, isDark: isDark),
                    ),
                  ),
                ],
              ),

              // ── Left edge hover zone (always present, triggers sidebar) ──
              Positioned(
                top: 0, left: 0, bottom: 0, width: 16,
                child: MouseRegion(
                  opaque: false,
                  onEnter: (_) => _onSidebarHoverEnter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildView({required int index, required String displayUser, required bool isDark}) {
    switch (index) {
      case 0:
        return ResidentHomeView(key: const ValueKey('home'), displayUser: displayUser, houseId: _houseId, isDark: isDark);
      case 1:
        return ResidentRepairView(key: const ValueKey('repair'), isDark: isDark);
      case 2:
        return ResidentHistoryView(key: const ValueKey('history'), isDark: isDark);
      case 3:
        return ResidentProfileView(key: const ValueKey('profile'), displayUser: displayUser, isDark: isDark);
      case 4:
        return const SettingsView(key: ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: DashboardTheme.cardDecoration().copyWith(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: DashboardTheme.error.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [DashboardTheme.error.withOpacity(0.08), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DashboardTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: DashboardTheme.error.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.power_settings_new_rounded, color: DashboardTheme.error, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SESSION TERMINATION',
                        style: GoogleFonts.outfit(color: DashboardTheme.error, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to sign out?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: DashboardTheme.textSecondary, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dialogButton(label: 'CANCEL', onTap: () => Navigator.pop(context), color: DashboardTheme.textPale, isGlassy: true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dialogButton(
                          label: 'LOGOUT',
                          onTap: () async {
                            await AuthRepository.instance.logout();
                            if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          },
                          color: DashboardTheme.error,
                          isPrimary: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButton({required String label, required VoidCallback onTap, required Color color, bool isPrimary = false, bool isGlassy = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary ? DashboardTheme.error.withOpacity(0.15) : (isGlassy ? DashboardTheme.surfaceSecondary : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}
