import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/hover_sidebar.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/shared/widgets/pin_verification_overlay.dart';

class TechnicianViewScreen extends StatefulWidget {
  const TechnicianViewScreen({super.key});

  @override
  State<TechnicianViewScreen> createState() => _TechnicianViewScreenState();
}

class _TechnicianViewScreenState extends State<TechnicianViewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _displayName = "Loading...";
  String _displayRole = "TECHNICIAN";
  String _displayEmail = "";
  String _displayPhone = "";
  String _displayImage = "assets/resident_profile.png";
  bool _sidebarOpen = false;

  // New state for task management
  String? _selectedTaskFilter = "All";
  bool _isSubmitting = false;
  RepairRequest? _selectedTask;
  int _selectedCalendarDay = DateTime.now().day;
  final TextEditingController _notesController = TextEditingController();
  final List<XFile> _attachedImages = [];
  final ImagePicker _picker = ImagePicker();

  // ── Sidebar animation ──
  late AnimationController _sidebarAnim;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _attachedImages.add(image);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Design Tokens - Now using dynamic DashboardTheme
  Color get _bgMain => DashboardTheme.background;
  Color get _bgSidebar => DashboardTheme.surface;
  Color get _primaryBlue => DashboardTheme.primary;
  Color get _gold => DashboardTheme.accentAmber;
  Color get _textMain => DashboardTheme.textMain;
  Color get _textMuted => DashboardTheme.textSecondary;
  Color get _border => DashboardTheme.border;

  final List<SidebarItem> _navItems = [
    const SidebarItem(
        index: 0, icon: Icons.assignment_outlined, label: "ALL TASKS"),
    const SidebarItem(
        index: 1, icon: Icons.calendar_month_outlined, label: "SCHEDULE"),
    const SidebarItem(index: 2, icon: Icons.person_outline, label: "PROFILE"),
    const SidebarItem(
        index: 3, icon: Icons.settings_outlined, label: "SETTINGS"),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    RepairRepository.instance.fetchHistory();
    _sidebarAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150), value: 0.0);
  }

  @override
  void dispose() {
    _sidebarAnim.dispose();
    _notesController.dispose();
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

  List<RepairRequest> _getAssignedTasks(List<RepairRequest> allRepairs) {
    final searchName = _displayName.trim().toLowerCase();
    if (searchName == "loading...") return [];

    return allRepairs.where((t) {
      return t.assignedStaff.any((s) => s.trim().toLowerCase() == searchName);
    }).toList();
  }

  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success']) {
      final data = result['data'];
      if (mounted) {
        setState(() {
          _displayName = (data['name'] ?? '').toString();
          _displayRole = (data['role'] ?? 'TECHNICIAN').toString();
          _displayEmail = (data['email'] ?? '').toString();
          _displayPhone = (data['phone'] ?? '').toString();
          _displayImage =
              (data['picture_uri'] ?? 'assets/resident_profile.png').toString();
        });
      }
    } else if (result['expired'] == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: _bgMain,
          body: Stack(
            children: [
              // ── Main Content ──
              Positioned.fill(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<List<RepairRequest>>(
                    valueListenable: RepairRepository.instance.repairsNotifier,
                    builder: (context, repairs, child) {
                      final assignedTasks = _getAssignedTasks(repairs);
                      return Column(
                        children: [
                          _buildHeader(assignedTasks),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: _buildPageContent(_currentIndex, repairs),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Scrim ──
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_sidebarOpen,
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: AnimatedBuilder(
                      animation: _sidebarAnim,
                      builder: (context, _) => Container(
                        color:
                            Colors.black.withOpacity(0.45 * _sidebarAnim.value),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Sidebar ──
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
  }

  Widget _buildSidebarContent() {
    return Material(
      color: _bgSidebar,
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TECH PORTAL",
                    style: GoogleFonts.outfit(
                      color: _primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayName,
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _displayRole,
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
            Divider(color: _border, height: 32),
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
                      onTap: () => setState(() => _currentIndex = i),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon,
                                size: 20,
                                color: isSelected
                                    ? _primaryBlue
                                    : DashboardTheme.textPale),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? _primaryBlue
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                onTap: () => _showLogoutConfirmation(context),
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
                        "LOGOUT",
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
                          border: Border.all(
                              color: DashboardTheme.error.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.power_settings_new_rounded,
                            color: DashboardTheme.error, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text("SESSION TERMINATION",
                          style: GoogleFonts.shareTechMono(
                              color: DashboardTheme.error,
                              fontSize: 18,
                              letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(
                        "Are you sure you want to log out from the Technician Portal?",
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
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: BorderSide(
                                color:
                                    DashboardTheme.textPale.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text("CANCEL",
                              style: GoogleFonts.notoSans(
                                  color: DashboardTheme.textPale,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await AuthRepository.instance.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                DashboardTheme.error.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text("LOGOUT",
                              style: GoogleFonts.notoSans(
                                  color: DashboardTheme.error,
                                  fontWeight: FontWeight.bold)),
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

  Widget _buildHeader(List<RepairRequest> assignedTasks) {
    final todayTasks = assignedTasks
        .where((t) =>
            t.status == "IN PROGRESS" ||
            t.status == "URGENT" ||
            t.status == "ASSIGNED")
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: _bgSidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _toggleSidebar,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.menu_rounded, color: _primaryBlue, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _navItems[_currentIndex].label == "ALL TASKS"
                        ? "Assigned Tasks"
                        : _navItems[_currentIndex].label,
                    style: GoogleFonts.kanit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: _textMain),
                  ),
                  Text(
                    "Hello $_displayName | You have $todayTasks tasks today",
                    style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: _textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          // Clean Avatar in header
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: _primaryBlue.withOpacity(0.2), width: 2),
            ),
            child: ClipOval(
              child: _displayImage.startsWith('http')
                  ? Image.network(_displayImage, fit: BoxFit.cover)
                  : Image.asset(_displayImage, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index, List<RepairRequest> allRepairs) {
    switch (index) {
      case 0:
        if (_selectedTask != null) {
          return _buildTaskDetailView(_selectedTask!);
        }
        return _buildTasksPage(allRepairs);
      case 1:
        return _buildCalendarPage(allRepairs);
      case 2:
        return ProfileView(
          name: _displayName,
          email: _displayEmail,
          phone: _displayPhone,
          role: _displayRole,
          imagePath: _displayImage,
          onMenuTap: _toggleSidebar,
          onProfileUpdated: _fetchUserProfile,
        );
      case 3:
        return const SettingsView();
      default:
        return _buildTasksPage(allRepairs);
    }
  }

  // Removed redundant builders as they are now imported from shared views

  Widget _buildTasksPage(List<RepairRequest> allRepairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip Filters (Matched Mockup)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip("All", _selectedTaskFilter == "All"),
              const SizedBox(width: 16),
              _filterChip("Assigned", _selectedTaskFilter == "Assigned"),
              const SizedBox(width: 16),
              _filterChip("In Progress", _selectedTaskFilter == "In Progress"),
              const SizedBox(width: 16),
              _filterChip("Completed", _selectedTaskFilter == "Completed"),
              const SizedBox(width: 16),
              _filterChip("Evaluated", _selectedTaskFilter == "Evaluated"),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Task Grid
        (() {
          final rawTasks = _getAssignedTasks(allRepairs);
          final filteredTasks = rawTasks.where((t) {
            if (_selectedTaskFilter == "All") return true;
            if (_selectedTaskFilter == "Assigned")
              return t.status == "ASSIGNED" || t.status == "URGENT";
            if (_selectedTaskFilter == "In Progress")
              return t.status == "IN PROGRESS";
            if (_selectedTaskFilter == "Completed")
              return t.status == "COMPLETED";
            if (_selectedTaskFilter == "Evaluated")
              return t.status == "EVALUATED";
            return true;
          }).toList();

          if (filteredTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Text("No tasks in this category",
                    style: GoogleFonts.kanit(color: _textMuted)),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.4,
            ),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final t = filteredTasks[index];
              // Map DashboardData status to UI status
              final uiStatus = t.status.toLowerCase();
              final displayStatus = t.status == "URGENT"
                  ? "Urgent"
                  : (t.status == "IN PROGRESS"
                      ? "In Progress"
                      : (t.status == "COMPLETED"
                          ? "Completed"
                          : (t.status == "EVALUATED"
                              ? "Evaluated"
                              : (t.status == "CANCELED" ||
                                      t.status == "DECLINED"
                                  ? "Cancelled"
                                  : "Assigned"))));

              return _techWorkCard(t, uiStatus, displayStatus);
            },
          );
        })(),
      ],
    );
  }

  Widget _buildCalendarPage(List<RepairRequest> allRepairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text("Your Schedule",
            style: GoogleFonts.kanit(
                fontSize: 28, fontWeight: FontWeight.bold, color: _textMain)),
        const SizedBox(height: 8),
        Text("Check your appointments and plan your tasks",
            style: GoogleFonts.kanit(fontSize: 14, color: _textMuted)),
        const SizedBox(height: 32),

        // Main Calendar Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Grid (Left)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _bgSidebar,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Text("March 2026",
                        style: GoogleFonts.kanit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildCalendarGrid(allRepairs),
                    const SizedBox(height: 24),
                    _buildCalendarLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Day Details (Right)
            SizedBox(
              width: 350,
              child: _buildDayDetailCard(allRepairs),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Upcoming Section
        Text("รายการที่ใกล้ถึงกำหนด",
            style: GoogleFonts.kanit(
                fontSize: 20, fontWeight: FontWeight.bold, color: _textMain)),
        const SizedBox(height: 16),
        _buildUpcomingList(allRepairs),
      ],
    );
  }

  Widget _buildCalendarGrid(List<RepairRequest> allRepairs) {
    final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: days
              .map((d) => Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                      child: Text(d,
                          style: GoogleFonts.kanit(
                              fontSize: 12, color: _textMuted)))))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Calendar Rows (March 2026 starts on Sunday)
        for (var i = 0; i < 5; i++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 1; j <= 7; j++) ...[
                if (i * 7 + j <= 31)
                  _calendarDay(i * 7 + j, allRepairs)
                else
                  const SizedBox(width: 60, height: 48),
                if (j < 7) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _calendarDay(int day, List<RepairRequest> allRepairs) {
    bool isSelected = _selectedCalendarDay == day;

    final assignedTasks = _getAssignedTasks(allRepairs);
    final dayTasks = assignedTasks.where((t) {
      if (t.appointmentDate == null) return false;
      // Filter for March (3) to match current mockup alignment
      return t.appointmentDate!.day == day && t.appointmentDate!.month == 3;
    }).toList();

    bool isUpcoming =
        dayTasks.any((t) => t.status == "IN PROGRESS" || t.status == "URGENT" || t.status == "ASSIGNED");

    Color bg = _bgSidebar;
    Color textColor = _textMain;
    BoxBorder border = Border.all(color: Colors.transparent);

    if (isSelected) {
      bg = const Color(0xFFFFF7ED); // Amber 50
      textColor = const Color(0xFFD97706); // Amber 600
      border = Border.all(color: const Color(0xFFF59E0B), width: 2);
    } else if (isUpcoming) {
      bg = const Color(0xFFECFDF5); // Green 50
      textColor = const Color(0xFF059669); // Green 600
    }

    return InkWell(
      onTap: () => setState(() => _selectedCalendarDay = day),
      child: Container(
        width: 60,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day.toString(),
                style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w600, color: textColor)),
            if (isUpcoming || isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Upcoming", const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _legendItem("Selected", const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
      ],
    );
  }

  Widget _buildDayDetailCard(List<RepairRequest> allRepairs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Schedule for",
              style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
          Text("$_selectedCalendarDay March 2026",
              style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706))),
          const SizedBox(height: 24),
          (() {
            final dayTasks = _getAssignedTasks(allRepairs).where((t) {
              if (t.appointmentDate == null) return false;
              // Compare day, month, and year with selected calendar day
              // For now, mockup month is always March (3) as per current design,
              // but we use DateTime's month to be safe.
              return t.appointmentDate!.day == _selectedCalendarDay &&
                  t.appointmentDate!.month ==
                      3; // Keep alignment with mockup month
            }).toList();

            if (dayTasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("No tasks for this day",
                      style: GoogleFonts.kanit(color: _textMuted)),
                ),
              );
            }

            return Column(
              children: dayTasks.map((t) {
                final displayStatus = t.status == "URGENT"
                    ? "Urgent"
                    : (t.status == "IN PROGRESS"
                        ? "Working"
                        : (t.status == "COMPLETED"
                            ? "Completed"
                            : (t.status == "EVALUATED"
                                ? "Evaluated"
                                : "Pending")));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _compactTaskTile(
                      t.title, displayStatus, t.requesterHouse ?? 'N/A', t.id),
                );
              }).toList(),
            );
          })(),
        ],
      ),
    );
  }

  Widget _compactTaskTile(
      String title, String status, String house, String id) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _gold, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(DashboardTheme.isDarkMode.value ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: GoogleFonts.kanit(
                        color: _primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold, color: _textMain)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.home_outlined, size: 12, color: _textMuted),
              const SizedBox(width: 4),
              Text("House: $house",
                  style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList(List<RepairRequest> allRepairs) {
    final upcomingItems = _getAssignedTasks(allRepairs)
        .where((t) =>
            t.status == "ASSIGNED" ||
            t.status == "URGENT" ||
            t.status == "IN PROGRESS")
        .toList();

    // Sort chronologically by appointmentDate
    upcomingItems.sort((a, b) {
      if (a.appointmentDate == null && b.appointmentDate == null) return 0;
      if (a.appointmentDate == null) return 1;
      if (b.appointmentDate == null) return -1;
      return a.appointmentDate!.compareTo(b.appointmentDate!);
    });

    if (upcomingItems.isEmpty) {
      return Center(
        child: Text("No upcoming tasks",
            style: GoogleFonts.kanit(color: _textMuted)),
      );
    }

    return Column(
      children: upcomingItems.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: _bgSidebar,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold, color: _textMain)),
                    if (t.appointmentDate != null)
                      Text(
                        "Appointment: ${t.appointmentDate!.day}/${t.appointmentDate!.month}/${t.appointmentDate!.year}",
                        style: GoogleFonts.kanit(
                            fontSize: 12, color: _primaryBlue.withOpacity(0.8)),
                      )
                    else
                      Text(t.date,
                          style: GoogleFonts.kanit(
                              fontSize: 12, color: _textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _textMuted),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTaskDetails(RepairRequest task) {
    setState(() => _selectedTask = task);
  }

  Widget _buildTaskDetailView(RepairRequest task) {
    final statusColor = task.status == 'URGENT'
        ? const Color(0xFFFF3333)
        : task.status == 'IN PROGRESS'
            ? _gold
            : (task.status == 'COMPLETED' || task.status == 'EVALUATED')
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B);
    final statusLabel = task.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── BACK NAV ──
        InkWell(
          onTap: () => setState(() => _selectedTask = null),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.west_rounded, size: 18, color: _textMuted),
              const SizedBox(width: 10),
              Text("BACK",
                  style: GoogleFonts.kanit(
                      color: _textMuted,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // ── HERO TITLE — Oversized, editorial ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thick status accent bar
            Container(
              width: 6,
              height: 72,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiny label
                  Text(
                      "${task.id}  ·  ${task.tasks.isNotEmpty ? task.tasks.first.urgency : ''}"
                          .toUpperCase(),
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _textMuted,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  // MASSIVE title
                  Text(task.title,
                      style: GoogleFonts.kanit(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: _textMain,
                          height: 1.1,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            // Status badge — clean
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel.toUpperCase(),
                  style: GoogleFonts.kanit(
                      color: statusColor == _gold ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 2)),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // ── MAIN CONTENT ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ════ LEFT COLUMN ════
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ▌ REQUESTER — Bold name, clean info
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold, width: 2),
                        ),
                        child: ClipOval(
                          child: (task.requesterProfileUrl != null &&
                                  task.requesterProfileUrl!.isNotEmpty)
                              ? Image.network(
                                  task.requesterProfileUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: _gold.withOpacity(0.5)),
                                )
                              : Icon(Icons.person_rounded,
                                  size: 32, color: _gold.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.requesterName ?? "Unknown Requester",
                                style: GoogleFonts.kanit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _textMain)),
                            const SizedBox(height: 4),
                            Text(
                                "${task.requesterHouse ?? 'N/AAddress'}  ·  ${task.requesterPhone ?? ''}  ·  ${task.requesterEmail ?? ''}  ·  ${task.appointmentDate != null ? 'Appt: ' + task.appointmentDate!.day.toString() + '/' + task.appointmentDate!.month.toString() + '/' + task.appointmentDate!.year.toString() : 'Created: ' + task.date}",
                                style: GoogleFonts.kanit(
                                    fontSize: 13,
                                    color: _textMuted,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ▌ TASKS / OBJECTS — FE-03 Workflow
                  Text("JOBS / OBJECTS",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (task.tasks.isEmpty)
                    Text("No specific tasks listed.",
                        style: GoogleFonts.kanit(color: _textMuted))
                  else
                    ...task.tasks.map((t) => _buildTaskItem(t, task.status)),

                  const SizedBox(height: 32),
                  Container(
                      height: 1, width: 80, color: _gold.withOpacity(0.4)),

                  const SizedBox(height: 40),

                  // ▌ 3D VIEW — Clean, dark
                  Text("REPAIR AREA",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bgSidebar,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border.withOpacity(0.5)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar_rounded,
                                  size: 56, color: _gold.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text("3D MODEL",
                                  style: GoogleFonts.kanit(
                                      color: _textMuted.withOpacity(0.5),
                                      fontSize: 12,
                                      letterSpacing: 3)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _bgSidebar,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text("📍 ${task.requesterHouse ?? 'N/A'}",
                                style: GoogleFonts.kanit(
                                    fontSize: 12, color: _textMuted)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 48),

            // ════ RIGHT COLUMN ════
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ▌ JOB STATUS — Ultra-minimal stepper
                  Text("STATUS",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _stepper([
                    _StepData("Assigned", task.date, true),
                    _StepData(
                        "Began",
                        "Work started",
                        task.status == 'IN PROGRESS' ||
                            task.status == 'COMPLETED' ||
                            task.status == 'EVALUATED'),
                    _StepData(
                        "Completed",
                        "Work finished",
                        task.status == 'COMPLETED' ||
                            task.status == 'EVALUATED'),
                    _StepData("Evaluated", "Resident feedback",
                        task.status == 'EVALUATED'),
                  ]),

                  const SizedBox(height: 40),

                  // ▌ ACTION BUTTON — Bold, full-width block
                  // ▌ ACTION BUTTON — SRS FE-03 Workflow
                  if (task.status == 'ASSIGNED' ||
                      task.status == 'URGENT' ||
                      task.status == 'CREATED')
                    _actionBlock(
                      icon: Icons.play_arrow_rounded,
                      label: "START WORK",
                      color: const Color(0xFFF59E0B),
                      textColor: Colors.black,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: DashboardTheme.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text("ยืนยันเริ่มงาน",
                                style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textMain,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            content: Text("เริ่มงาน ${task.title}?",
                                style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textSecondary,
                                    fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text("ยกเลิก",
                                    style: GoogleFonts.notoSans(
                                        color: DashboardTheme.textPale,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  // PIN verification before starting work
                                  final pinOk = await showPinVerificationOverlay(context);
                                  if (pinOk != true) return;

                                  bool success = await RepairRepository.instance
                                      .updateStatus(task.id, 'BEGAN');
                                  if (success) {
                                    // Find the updated task from the repository to refresh the detail view
                                    if (mounted) {
                                      final updated = RepairRepository
                                          .instance.repairsNotifier.value
                                          .firstWhere((r) => r.id == task.id,
                                              orElse: () => task);
                                      setState(() => _selectedTask = updated);
                                    }
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "เกิดข้อผิดพลาดในการเริ่มงาน")));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("เริ่มงาน",
                                    style: GoogleFonts.notoSans(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else if (task.status == 'IN PROGRESS')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Turn-in report header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DashboardTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: DashboardTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded,
                                  color: DashboardTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("TURN-IN REPORT",
                                      style: GoogleFonts.notoSans(
                                          color: DashboardTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5)),
                                  Text("กรอกรายงานแล้วส่งงาน",
                                      style: GoogleFonts.notoSans(
                                          color: DashboardTheme.textPale,
                                          fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Submit report button
                        _actionBlock(
                          icon: Icons.check_circle_outline_rounded,
                          label: "SUBMIT & FINISH",
                          color: const Color(0xFF10B981),
                          textColor: Colors.white,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: DashboardTheme.surface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text("ส่งรายงานการซ่อม",
                                    style: GoogleFonts.notoSans(
                                        color: DashboardTheme.textMain,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ยืนยันการส่งงาน ${task.title}?",
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textSecondary,
                                            fontSize: 13)),
                                    const SizedBox(height: 12),
                                    if (_attachedImages.isNotEmpty)
                                      Text(
                                          "📎 ${_attachedImages.length} รูปแนบ",
                                          style: GoogleFonts.notoSans(
                                              color: DashboardTheme.primary,
                                              fontSize: 12)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text("ยกเลิก",
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textPale,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Optional: Check if all tasks have reports
                                      bool allReported = task.tasks.every((t) =>
                                          t.taskReport != null &&
                                          t.taskReport!.isNotEmpty);

                                      if (!allReported) {
                                        bool confirm = await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor:
                                                DashboardTheme.surface,
                                            title: Text("ยังกรอกรายงานไม่ครบ",
                                                style: GoogleFonts.notoSans(
                                                    color: DashboardTheme
                                                        .textMain)),
                                            content: Text(
                                                "คุณยังไม่ได้กรอกรายงานสำหรับบางรายการ ยืนยันที่จะส่งงานหรือไม่?"),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: Text("กลับไปกรอก")),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: Text("ยืนยันส่งงาน")),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                      }

                                      Navigator.pop(ctx);
                                      // PIN verification before completing work
                                      final pinOk = await showPinVerificationOverlay(context);
                                      if (pinOk != true) return;

                                      bool success = await RepairRepository
                                          .instance
                                          .updateStatus(task.id, 'COMPLETED');
                                      if (success) {
                                        if (mounted) {
                                          setState(() => _selectedTask = null);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text("ส่งงานเสร็จสิ้น")));
                                        }
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "เกิดข้อผิดพลาดในการส่งงาน")));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text("ส่งงาน",
                                        style: GoogleFonts.notoSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  else if (task.status == 'COMPLETED' ||
                      task.status == 'EVALUATED')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text("COMPLETED ✓",
                            style: GoogleFonts.kanit(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 2)),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // ▌ NOTES — Clean input
                  Text("NOTES",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    style: GoogleFonts.kanit(
                        color: _textMain, fontSize: 14, height: 1.6),
                    decoration: InputDecoration(
                      hintText: "Repair observations...",
                      hintStyle: GoogleFonts.kanit(
                          fontSize: 14, color: _textMuted.withOpacity(0.3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _gold.withOpacity(0.6)),
                      ),
                      filled: true,
                      fillColor: _bgSidebar,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ▌ ATTACHMENTS — Image upload area
                  Text("ATTACHMENTS",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  // Attached image preview grid
                  if (_attachedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachedImages.asMap().entries.map((e) {
                          return Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _bgSidebar,
                                  border: Border.all(
                                      color: _border.withOpacity(0.5)),
                                  image: DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(e.value.path)
                                            as ImageProvider
                                        : FileImage(File(e.value.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _attachedImages.removeAt(e.key)),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  // Upload button
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _border.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 28, color: _textMuted.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text("ATTACH PHOTO",
                              style: GoogleFonts.kanit(
                                  fontSize: 11,
                                  color: _textMuted.withOpacity(0.4),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _saveGeneralNote(task),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFFEAB308)))
                          : Text("SAVE NOTE",
                              style: GoogleFonts.kanit(
                                  color: _gold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Bold action block — solid color, no gradient fuss
  Widget _actionBlock({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _filterChip(String label, bool active) {
    return InkWell(
      onTap: () => setState(() => _selectedTaskFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : _bgSidebar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _primaryBlue : _border),
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            color: active ? Colors.white : _textMain,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _techWorkCard(RepairRequest t, String uiStatus, String displayStatus) {
    String category = t.tasks.isNotEmpty ? t.tasks.first.urgency : "General";

    Color statusColor = const Color(0xFFF59E0B); // Pending (Gold)
    if (uiStatus == 'in progress')
      statusColor = const Color(0xFF10B981); // Working (Green)
    if (uiStatus == 'completed' || uiStatus == 'evaluated')
      statusColor = const Color(0xFF3B82F6); // Done (Blue)
    if (uiStatus == 'urgent')
      statusColor = const Color(0xFFFF3333); // Urgent (Red)

    return InkWell(
      onTap: () => _showTaskDetails(t),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _bgSidebar,
          border: Border.all(color: _border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP HEADER (Raw color block) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                border: Border(
                    bottom: BorderSide(color: statusColor.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category.toUpperCase(),
                      style: GoogleFonts.kanit(
                          color: _textMain.withOpacity(0.7),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  Text(displayStatus.toUpperCase(),
                      style: GoogleFonts.kanit(
                          color: statusColor,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            // ── CONTENT BODY ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thick accent mark
                    Container(
                      width: 24,
                      height: 4,
                      color: statusColor,
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                    Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                            color: _textMain)),
                    const Spacer(),

                    // Details
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text("${t.requesterHouse ?? 'N/A'}",
                            style: GoogleFonts.kanit(
                                fontSize: 13,
                                color: _textMuted,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text("${t.date}",
                            style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: _textMuted.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── ACTION BUTTON (Full width, bold) ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _bgMain,
                border:
                    Border(top: BorderSide(color: _border.withOpacity(0.3))),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        t.status == 'ASSIGNED' || t.status == 'URGENT'
                            ? "START WORK"
                            : (t.status == 'IN PROGRESS'
                                ? "CONTINUE WORK"
                                : "VIEW DETAILS"),
                        style: GoogleFonts.kanit(
                            color: _gold,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: _gold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(RepairTask t, String requestStatus) {
    final bool canReport = requestStatus == 'IN PROGRESS';
    final bool hasReport = t.taskReport != null && t.taskReport!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSidebar.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasReport
                ? Colors.green.withOpacity(0.3)
                : _border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasReport ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 18,
                color: hasReport ? Colors.green : _gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.objectName ?? t.description,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
              ),
              if (canReport)
                IconButton(
                  icon: Icon(Icons.edit_note_rounded, color: _gold),
                  onPressed: () => _showReportDialog(t),
                  tooltip: "Add Report",
                ),
            ],
          ),
          if (hasReport)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(
                t.taskReport!,
                style: GoogleFonts.kanit(
                  fontSize: 13,
                  color: _textMain.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReportDialog(RepairTask task) {
    final TextEditingController reportController =
        TextEditingController(text: task.taskReport);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("รายงานการซ่อม: ${task.objectName ?? 'สิ่งของ'}",
            style: GoogleFonts.kanit(color: _textMain, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reportController,
              maxLines: 4,
              cursorColor: _gold,
              style: GoogleFonts.kanit(color: _textMain),
              decoration: InputDecoration(
                hintText: "สรุปผลการซ่อม/อาการที่พบ...",
                hintStyle: GoogleFonts.kanit(color: _textMuted),
                filled: true,
                fillColor: _bgSidebar,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ยกเลิก", style: GoogleFonts.kanit(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              String report = reportController.text.trim();
              if (report.isNotEmpty) {
                Navigator.pop(ctx);
                bool success = await RepairRepository.instance.updateTaskReport(
                  taskId: task.id,
                  status: 'InProgress',
                  report: report,
                );
                if (!mounted) return;
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("บันทึกไม่สำเร็จ")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("บันทึก",
                style: GoogleFonts.kanit(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _stepper(List<_StepData> steps) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        // Determine if this is the current "active" step (first incomplete one)
        final isActive = !s.done && (i == 0 || steps[i - 1].done);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: s.done
                        ? (i == steps.length - 1
                            ? const Color(0xFF10B981)
                            : _gold)
                        : (isActive
                            ? _gold.withOpacity(0.15)
                            : Colors.transparent),
                    border: Border.all(
                        color: s.done
                            ? Colors.transparent
                            : (isActive ? _gold : _border),
                        width: 2),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: _gold.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: s.done
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : (isActive
                          ? Center(
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: _gold, shape: BoxShape.circle)))
                          : null),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: s.done
                            ? [_gold, _gold.withOpacity(0.5)]
                            : [_border, _border],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: GoogleFonts.kanit(
                          fontWeight: FontWeight.bold,
                          fontSize: isActive ? 15 : 14,
                          color: s.done
                              ? _textMain
                              : (isActive ? _gold : _textMuted))),
                  Text(s.sub,
                      style:
                          GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _saveGeneralNote(RepairRequest request) async {
    final note = _notesController.text.trim();
    if (note.isEmpty && _attachedImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณากรอกหมายเหตุหรือแนบรูปภาพ")),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload images
      List<String> imageUrls = [];
      for (var file in _attachedImages) {
        String? url = await RepairRepository.instance.uploadImage(file);
        if (url != null) imageUrls.add(url);
      }

      // 2. Pick the first task to attach the report to
      if (request.tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ไม่พบรายการงานในคำขอนี้")),
          );
        }
        return;
      }

      final firstTask = request.tasks.first;

      // 3. Update task report and complete
      bool success = await RepairRepository.instance.updateTaskReport(
        taskId: firstTask.id,
        status: 'Completed',
        report: note,
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("บันทึกหมายเหตุและส่งงานเสร็จสิ้น")),
          );
          setState(() =>
              _selectedTask = null); // Close detail view and return to list
          RepairRepository.instance.fetchHistory(); // Refresh
          _notesController.clear();
          setState(() {
            _attachedImages.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึก")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _StepData {
  final String title;
  final String sub;
  final bool done;
  _StepData(this.title, this.sub, this.done);
}
