import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

// Shared
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/hover_sidebar.dart';

// Views
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/overview_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/tasks_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/technicians_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/statistics_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';

// Data
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/core/data/auth_repository.dart';


class LegalDashboardScreen extends StatefulWidget {
  const LegalDashboardScreen({super.key});

  @override
  State<LegalDashboardScreen> createState() => _LegalDashboardScreenState();
}

class _LegalDashboardScreenState extends State<LegalDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // ── Sidebar auto-hide ──
  late AnimationController _sidebarAnim;
  Timer? _hideTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _sidebarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
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
    if (mounted) _sidebarAnim.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onSidebarHoverEnter() { _isHovering = true; _showSidebar(); }
  void _onSidebarHoverExit() { _isHovering = false; _startHideTimer(); }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: DashboardTheme.background,
          body: Stack(
            children: [
              Row(
                children: [
                  // Animated sidebar
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
                          selectedIndex: _selectedIndex,
                          onIndexChanged: (i) {
                            setState(() => _selectedIndex = i);
                            _startHideTimer();
                          },
                          onLogout: () => _showLogoutConfirmation(context),
                          items: const [
                            SidebarItem(index: 0, icon: Icons.dashboard_rounded, label: "OVERVIEW"),
                            SidebarItem(index: 1, icon: Icons.assignment_rounded, label: "REQUESTS"),
                            SidebarItem(index: 2, icon: Icons.engineering_rounded, label: "STAFF"),
                            SidebarItem(index: 4, icon: Icons.analytics_rounded, label: "ANALYTICS"),
                            SidebarItem(index: 5, icon: Icons.person_rounded, label: "ACCOUNT"),
                            SidebarItem(index: 3, icon: Icons.settings_rounded, label: "SETTINGS"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RepaintBoundary(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildMainContent(),
                          ),
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: _buildHeader(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Left edge hover zone
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
              boxShadow: [
                BoxShadow(
                  color: DashboardTheme.error.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DashboardTheme.error.withOpacity(0.08),
                        Colors.transparent,
                      ],
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
                      terminalText("SESSION TERMINATION", color: DashboardTheme.error, fontSize: 18, letterSpacing: 2),
                      const SizedBox(height: 12),
                      Text(
                        "Are you sure you want to end your active session on the FCM Platform?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          color: DashboardTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: _dialogButton(
                          label: "CANCEL",
                          onTap: () => Navigator.pop(context),
                          color: DashboardTheme.textPale,
                          isGlassy: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dialogButton(
                          label: "LOGOUT",
                          onTap: () async {
                            await AuthRepository.instance.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            }
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
            child: terminalText(label, color: color, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_selectedIndex == 1) return const SizedBox.shrink(); // Hide on Request screen as per original design
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent, // Removed background as requested
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 0),
              Text(
                "TODAY'S REPAIR REQUESTS",
                style: GoogleFonts.notoSans(
                  color: Colors.white, // White font as requested
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _headerInfo('22°C', Icons.wb_sunny_rounded),
              _headerInfo('Humidity 49%', Icons.water_drop_rounded),
              _headerInfo('Wind 4 km/h', Icons.air_rounded),
              const SizedBox(width: 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DashboardTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.notoSans(
              color: Colors.white, // White font as requested
              fontSize: 10,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const OverviewView();
      case 1:
        return TasksView(
          technicians: DashboardData.technicians,
          onIndexChanged: (i) => setState(() => _selectedIndex = i),
        );
      case 2:
        return TechniciansView(technicians: DashboardData.technicians);
      case 3:
        return const SettingsView();
      case 4:
        return const StatisticsView();
      case 5:
        return ProfileView(
          name: "Admin Zeta",
          email: "admin@gmail.com",
          phone: "+66 88 777 9999",
          role: "Admin",
          imagePath: 'assets/images/profile_placeholder_2.jpg',
        );
      default:
        return const OverviewView();
    }
  }

}
