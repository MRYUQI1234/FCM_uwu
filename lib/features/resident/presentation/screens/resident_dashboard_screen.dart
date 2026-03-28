import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_home_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_history_view.dart';
import 'package:fcm_app/features/resident/presentation/views/resident_profile_view.dart';

// Vivorn Villa - Resident Dashboard (Main Shell)
// Sidebar overlay via hamburger menu anchored top-left

class ResidentDashboardScreen extends StatefulWidget {
  final String username;
  const ResidentDashboardScreen({super.key, this.username = ''});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _displayUsername = '';
  String _houseAddress = '123/45';
  String _houseSoi = '0';
  String? _activateDate;
  String? _pictureUri;
  late AnimationController _sidebarAnim;
  bool _sidebarOpen = false;
  final _ts = TranslationService.instance;

  // Sidebar nav items (no Repair)
  List<_NavItem> get _navItems => [
        _NavItem(Icons.dashboard_rounded, _ts.t('nav_dashboard')),
        _NavItem(Icons.history_rounded, _ts.t('nav_history')),
        _NavItem(Icons.person_rounded, _ts.t('nav_profile')),
        _NavItem(Icons.settings_rounded, _ts.t('nav_settings')),
      ];

  @override
  void initState() {
    super.initState();
    _displayUsername = widget.username;
    _fetchUserProfile();
    _sidebarAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150), value: 0.0);
  }

  @override
  void dispose() {
    _sidebarAnim.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarAnim.animateTo(1.0, curve: Curves.easeOutCubic);
    } else {
      _sidebarAnim.animateTo(0.0, curve: Curves.easeInCubic);
    }
  }

  void _closeSidebar() {
    if (_sidebarOpen) {
      setState(() => _sidebarOpen = false);
      _sidebarAnim.animateTo(0.0, curve: Curves.easeInCubic);
    }
  }

  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success']) {
      final data = result['data'];
      if (mounted) {
        setState(() {
          _displayUsername =
              (data['name'] ?? data['fullname'] ?? '').toString();
          _houseAddress = (data['house_address'] ?? 'N/A').toString();
          _houseSoi = (data['soi'] ?? 'N/A').toString();
          _activateDate = data['activate_date']?.toString();
          _pictureUri = data['picture_uri']?.toString();
          debugPrint("House ID: $_houseAddress, Activate Date: $_activateDate");
        });
      }
    } else if (result['expired'] == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  //ส่วนไหนไม่รู้
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final displayUser = _displayUsername.isNotEmpty
        ? _displayUsername
        : (args is String ? args : widget.username);

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<String>(
          valueListenable: _ts.currentLanguage,
          builder: (context, lang, _) {
            return Scaffold(
              backgroundColor: DashboardTheme.background,
              body: Stack(
                children: [
                  // ── Main content (full width, never shrinks) ──
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _buildView(
                          index: _currentIndex,
                          displayUser: displayUser,
                          isDark: isDark),
                    ),
                  ),

                  // ── Scrim (always in tree, pointer-ignored when closed) ──
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_sidebarOpen,
                      child: GestureDetector(
                        onTap: _closeSidebar,
                        child: AnimatedBuilder(
                          animation: _sidebarAnim,
                          builder: (context, _) => Container(
                            color: Colors.black
                                .withOpacity(0.45 * _sidebarAnim.value),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Overlay Sidebar (always in tree for warmup) ──
                  AnimatedBuilder(
                    animation: _sidebarAnim,
                    builder: (context, child) {
                      const w = 260.0;
                      return Positioned(
                        top: 0,
                        bottom: 0,
                        left: -w + (w * _sidebarAnim.value),
                        width: w,
                        child: child!,
                      );
                    },
                    child: _buildSidebarContent(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    return Material(
      color: DashboardTheme.surface,
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Brand ──
            //ส่วนหัว
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DashboardTheme.primary.withOpacity(0.1),
                    backgroundImage: (_pictureUri != null &&
                            _pictureUri!.isNotEmpty &&
                            _pictureUri!.startsWith('http'))
                        ? NetworkImage(_pictureUri!)
                        : const AssetImage('assets/resident_profile.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _ts.t('brand_title'),
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    //resident portal
                    //เปลี่ยน brand subtitle เป็นชื่อผู้ใช้
                    _displayUsername,
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textPale,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    //resident portal
                    //เปลี่ยน brand subtitle เป็นชื่อผู้ใช้
                    "${_ts.t('label_houseAddress')} $_houseAddress, ${_ts.t('label_houseSoi')} $_houseSoi",
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textPale,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  )
                ],
              ),
            ),
            Divider(color: DashboardTheme.border, height: 32),

            // ── Nav Items ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, i) {
                  final item = _navItems[i];
                  final isSelected = _currentIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() => _currentIndex = i);
                        // Don't close sidebar immediately
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DashboardTheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? DashboardTheme.primary.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon,
                                size: 20,
                                color: isSelected
                                    ? DashboardTheme.primary
                                    : DashboardTheme.textPale),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? DashboardTheme.primary
                                    : DashboardTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                onTap: () {
                  _closeSidebar();
                  _showLogoutConfirmation(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: DashboardTheme.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 20,
                          color: DashboardTheme.error.withOpacity(0.8)),
                      const SizedBox(width: 14),
                      Text(
                        _ts.t('logout_confirm'),
                        style: GoogleFonts.outfit(
                          color: DashboardTheme.error.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView(
      {required int index, required String displayUser, required bool isDark}) {
    switch (index) {
      case 0:
        return ResidentHomeView(
            key: const ValueKey('home'),
            displayUser: displayUser,
            houseId: _houseAddress,
            activateDate: _activateDate,
            isDark: isDark,
            onMenuTap: _toggleSidebar,
            onHistoryRequested: () {
              setState(() => _currentIndex = 1);
            });
      case 1:
        return ResidentHistoryView(
            key: const ValueKey('history'),
            isDark: isDark,
            onMenuTap: _toggleSidebar);
      case 2:
        return ResidentProfileView(
            key: const ValueKey('profile'),
            displayUser: displayUser,
            pictureUri: _pictureUri,
            isDark: isDark,
            onMenuTap: _toggleSidebar,
            onProfileUpdated: _fetchUserProfile);
      case 3:
        return SettingsView(
            key: const ValueKey('settings'), onMenuTap: _toggleSidebar);
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
              border: Border.all(
                  color: DashboardTheme.error.withOpacity(0.3), width: 1.5),
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
                      colors: [
                        DashboardTheme.error.withOpacity(0.08),
                        Colors.transparent
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
                          border: Border.all(
                              color: DashboardTheme.error.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.power_settings_new_rounded,
                            color: DashboardTheme.error, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(_ts.t('logout_title'),
                          style: GoogleFonts.outfit(
                              color: DashboardTheme.error,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(_ts.t('logout_body'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: DashboardTheme.textSecondary,
                              fontSize: 14,
                              height: 1.5)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    children: [
                      Expanded(
                          child: _dialogButton(
                              label: _ts.t('logout_cancel'),
                              onTap: () => Navigator.pop(context),
                              color: DashboardTheme.textPale,
                              isGlassy: true)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dialogButton(
                          label: _ts.t('logout_confirm'),
                          onTap: () async {
                            await AuthRepository.instance.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
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

  Widget _dialogButton(
      {required String label,
      required VoidCallback onTap,
      required Color color,
      bool isPrimary = false,
      bool isGlassy = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isPrimary
                ? DashboardTheme.error.withOpacity(0.15)
                : (isGlassy
                    ? DashboardTheme.surfaceSecondary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}
