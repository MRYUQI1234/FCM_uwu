import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/hover_sidebar.dart';
import 'package:fcm_app/core/data/auth_repository.dart';

class TechnicianViewScreen extends StatefulWidget {
  const TechnicianViewScreen({super.key});

  @override
  State<TechnicianViewScreen> createState() => _TechnicianViewScreenState();
}

class _TechnicianViewScreenState extends State<TechnicianViewScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;
  String? _selectedTaskFilter = "All";
  Map<String, dynamic>? _selectedTask;
  int _selectedCalendarDay = 12;
  final String _techName = "Wichai";
  final String _techRole = "SENIOR ELECTRICIAN";
  final List<XFile> _attachedImages = [];
  final ImagePicker _picker = ImagePicker();

  // ── Sidebar auto-hide ──
  late AnimationController _sidebarAnim;
  Timer? _hideTimer;
  bool _isHovering = false;

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
    const SidebarItem(index: 3, icon: Icons.settings_outlined, label: "SETTINGS"),
  ];

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
          backgroundColor: _bgMain,
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
                          selectedIndex: _selectedNavIndex,
                          onIndexChanged: (i) {
                            setState(() { _selectedNavIndex = i; _selectedTask = null; });
                            _startHideTimer();
                          },
                          onLogout: () => _showLogoutConfirmation(context),
                          brandTitle: "TECH PORTAL",
                          brandSubtitle: "WICHAI | SENIOR ELECTRICIAN",
                          items: _navItems,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RepaintBoundary(
                      child: Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: _buildPageContent(_selectedNavIndex),
                            ),
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
                        child: Icon(Icons.power_settings_new_rounded,
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
                                color: DashboardTheme.textPale.withOpacity(0.2)),
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

  List<Map<String, dynamic>> _getAssignedTasks() {
    return DashboardData.tasks
        .where((t) => (t['staffNames'] as List).contains(_techName))
        .toList();
  }

  Widget _buildHeader() {
    final assignedTasks = _getAssignedTasks();
    final todayTasks = assignedTasks
        .where((t) => t['status'] == "WORKING" || t['status'] == "URGENT" || t['status'] == "PENDING")
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: _bgSidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navItems[_selectedNavIndex].label == "ALL TASKS"
                    ? "Assigned Tasks"
                    : _navItems[_selectedNavIndex].label,
                style: GoogleFonts.kanit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _textMain),
              ),
              Text(
                "Hello $_techName | You have $todayTasks tasks to perform today",
                style: GoogleFonts.kanit(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        if (_selectedTask != null) {
          return _buildTaskDetailView(_selectedTask!);
        }
        return _buildTasksPage();
      case 1:
        return _buildCalendarPage();
      case 2:
        final wichai = DashboardData.technicians.firstWhere((t) => t['name'] == _techName);
        return ProfileView(
          name: wichai['name'],
          email: wichai['email'],
          phone: wichai['phone'],
          role: wichai['role'],
          imagePath: wichai['image'],
        );
      case 3:
        return const SettingsView();
      default:
        return _buildTasksPage();
    }
  }

  // Removed redundant builders as they are now imported from shared views

  Widget _buildTasksPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip Filters (Matched Mockup)
        Row(
          children: [
            _filterChip("All", _selectedTaskFilter == "All"),
            const SizedBox(width: 16),
            _filterChip("Working", _selectedTaskFilter == "Working"),
            const SizedBox(width: 16),
            _filterChip("Pending", _selectedTaskFilter == "Pending"),
            const SizedBox(width: 16),
            _filterChip("Completed", _selectedTaskFilter == "Completed"),
          ],
        ),
        const SizedBox(height: 32),
        // Task Grid
        (() {
          final rawTasks = _getAssignedTasks();
          final filteredTasks = rawTasks.where((t) {
            if (_selectedTaskFilter == "All") return true;
            if (_selectedTaskFilter == "Working") return t['status'] == "WORKING";
            if (_selectedTaskFilter == "Pending") return t['status'] == "PENDING" || t['status'] == "URGENT";
            if (_selectedTaskFilter == "Completed") return t['status'] == "DONE";
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
              final uiStatus = t['status'].toString().toLowerCase();
              final displayStatus = t['status'] == "URGENT" ? "Urgent" : 
                                   (t['status'] == "WORKING" ? "Working" : 
                                   (t['status'] == "DONE" ? "Completed" : "Pending"));
              
              final mappedTask = {
                ...t,
                "uiStatus": uiStatus,
                "statusText": displayStatus,
              };
              return _techWorkCard(mappedTask);
            },
          );
        })(),
      ],
    );
  }

  Widget _buildCalendarPage() {
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
                    Text("February 2026",
                        style: GoogleFonts.kanit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildCalendarGrid(),
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
              child: _buildDayDetailCard(),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Upcoming Section
        Text("รายการที่ใกล้ถึงกำหนด",
            style: GoogleFonts.kanit(
                fontSize: 20, fontWeight: FontWeight.bold, color: _textMain)),
        const SizedBox(height: 16),
        _buildUpcomingList(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
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
        // Calendar Rows (Simplified for Feb 2026 starts on Sunday)
        for (var i = 0; i < 4; i++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 1; j <= 7; j++) ...[
                _calendarDay(i * 7 + j),
                if (j < 7) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _calendarDay(int day) {
    bool isSelected = _selectedCalendarDay == day;
    
    final assignedTasks = _getAssignedTasks();
    final dayTasks = assignedTasks.where((t) {
      final dateStr = t['date'] as String;
      final dayPart = int.tryParse(dateStr.split(' ')[0]) ?? 0;
      return dayPart == day;
    }).toList();

    bool isBusy = dayTasks.any((t) => t['status'] == "WORKING" || t['status'] == "URGENT");
    bool hasPending = dayTasks.any((t) => t['status'] == "PENDING");
    bool isAvailable = !isBusy && !hasPending && !isSelected;

    Color bg = _bgSidebar;
    Color textColor = _textMain;
    BoxBorder border = Border.all(color: Colors.transparent);

    if (isSelected) {
      bg = const Color(0xFFFFF7ED); // Amber 50
      textColor = const Color(0xFFD97706); // Amber 600
      border = Border.all(color: const Color(0xFFF59E0B), width: 2);
    } else if (isBusy) {
      bg = const Color(0xFFFEF2F2); // Red 50
      textColor = const Color(0xFFDC2626); // Red 600
    } else if (hasPending) {
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
            if (isBusy || isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.red,
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
        _legendItem("Busy", Colors.red),
        const SizedBox(width: 16),
        _legendItem("Available", const Color(0xFF059669)),
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

  Widget _buildDayDetailCard() {
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
          Text("$_selectedCalendarDay February 2026",
              style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706))),
          const SizedBox(height: 24),
          (() {
            final dayTasks = _getAssignedTasks().where((t) {
              final dateStr = t['date'] as String;
              final dayPart = int.tryParse(dateStr.split(' ')[0]) ?? 0;
              return dayPart == _selectedCalendarDay;
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
                final displayStatus = t['status'] == "URGENT" ? "Urgent" : 
                                     (t['status'] == "WORKING" ? "Working" : 
                                     (t['status'] == "DONE" ? "Completed" : "Pending"));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _compactTaskTile(t['title'], displayStatus, t['house'], t['id']),
                );
              }).toList(),
            );
          })(),
        ],
      ),
    );
  }

  Widget _compactTaskTile(String title, String status, String house, String id) {
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
              Text(id,
                  style: GoogleFonts.outfit(color: _textMuted, fontSize: 10)),
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

  Widget _buildUpcomingList() {
    final upcomingItems = _getAssignedTasks()
        .where((t) => t['status'] == "PENDING" || t['status'] == "URGENT")
        .toList();

    if (upcomingItems.isEmpty) {
      return Center(
        child: Text("No upcoming tasks", style: GoogleFonts.kanit(color: _textMuted)),
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
                    Text(t['title']!,
                        style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold, color: _textMain)),
                    Text(t['date']!,
                        style:
                            GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
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

  void _showTaskDetails(Map<String, dynamic> task) {
    setState(() => _selectedTask = task);
  }

  Widget _buildTaskDetailView(Map<String, dynamic> task) {
    final statusColor = task['status'] == 'URGENT'
        ? const Color(0xFFFF3333)
        : task['status'] == 'WORKING'
            ? _gold
            : task['status'] == 'DONE'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B);
    final statusLabel = task['statusText'] ?? task['status'] ?? "N/A";

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
              Text("BACK", style: GoogleFonts.kanit(
                  color: _textMuted, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
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
              width: 6, height: 72,
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
                  Text("${task['id'] ?? ''}  ·  ${task['category'] ?? ''}".toUpperCase(),
                      style: GoogleFonts.kanit(
                          fontSize: 11, color: _textMuted,
                          letterSpacing: 3, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  // MASSIVE title
                  Text(task['title'] ?? "Task Detail",
                      style: GoogleFonts.kanit(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: _textMain, height: 1.1, letterSpacing: -0.5)),
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
                      fontSize: 12, letterSpacing: 2)),
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
                      // Simple avatar — no double ring, no gradient
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold, width: 2.5),
                          image: DecorationImage(
                            image: AssetImage(task['requesterImage'] ?? 'assets/images/profile_placeholder_2.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task['requester'] ?? "Unknown",
                                style: GoogleFonts.kanit(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: _textMain)),
                            const SizedBox(height: 4),
                            Text("${task['house'] ?? ''}  ·  ${task['requesterAccount'] ?? ''}  ·  ${task['date'] ?? ''}",
                                style: GoogleFonts.kanit(
                                    fontSize: 13, color: _textMuted, letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ▌ REPORT — Raw typography, no frame
                  Text("REPORT", style: GoogleFonts.kanit(
                      fontSize: 11, color: _gold,
                      letterSpacing: 4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text(
                    task['report'] ?? "No details provided.",
                    style: GoogleFonts.kanit(
                      color: _textMain.withOpacity(0.85),
                      fontSize: 16, height: 1.8,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  // Thin gold line
                  const SizedBox(height: 32),
                  Container(height: 1, width: 80, color: _gold.withOpacity(0.4)),

                  const SizedBox(height: 40),

                  // ▌ 3D VIEW — Clean, dark
                  Text("REPAIR AREA", style: GoogleFonts.kanit(
                      fontSize: 11, color: _gold,
                      letterSpacing: 4, fontWeight: FontWeight.w700)),
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
                              Text("3D MODEL", style: GoogleFonts.kanit(
                                  color: _textMuted.withOpacity(0.5),
                                  fontSize: 12, letterSpacing: 3)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 16, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _bgSidebar,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text("📍 ${task['house']}",
                                style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
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
                  Text("STATUS", style: GoogleFonts.kanit(
                      fontSize: 11, color: _gold,
                      letterSpacing: 4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _stepper([
                    _StepData("Assigned", task['date'] ?? 'N/A', true),
                    _StepData("On-Site", "Arrived at location",
                        task['status'] == 'WORKING' || task['status'] == 'DONE'),
                    _StepData("In Progress", "Work underway",
                        task['status'] == 'WORKING' || task['status'] == 'DONE'),
                    _StepData("Completed", "Pending review",
                        task['status'] == 'DONE'),
                  ]),

                  const SizedBox(height: 40),

                  // ▌ ACTION BUTTON — Bold, full-width block
                  // ▌ ACTION BUTTON — SRS FE-03 Workflow
                  if (task['status'] == 'PENDING' || task['status'] == 'URGENT')
                    _actionBlock(
                      icon: Icons.location_on_rounded,
                      label: "CHECK-IN AT SITE",
                      color: const Color(0xFFF59E0B),
                      textColor: Colors.black,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: DashboardTheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text("ยืนยันเริ่มงาน", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w900)),
                            content: Text("เริ่มงาน ${task['title']}?", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  setState(() => task['status'] = 'WORKING');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("เริ่มงานเรียบร้อย — สถานะเปลี่ยนเป็น 'กำลังดำเนินการ'", style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                                      backgroundColor: DashboardTheme.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("เริ่มงาน", style: GoogleFonts.notoSans(color: Colors.black, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else if (task['status'] == 'WORKING')
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
                            border: Border.all(color: DashboardTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded, color: DashboardTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("TURN-IN REPORT", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                  Text("กรอกรายงานแล้วส่งงาน", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 10)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text("ส่งรายงานการซ่อม", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w900)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ยืนยันการส่งงาน ${task['title']}?", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 12),
                                    if (_attachedImages.isNotEmpty)
                                      Text("📎 ${_attachedImages.length} รูปแนบ", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 12)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() => task['status'] = 'DONE');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("ส่งรายงานเรียบร้อย — สถานะเปลี่ยนเป็น 'เสร็จสิ้น'", style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text("ส่งงาน", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text("COMPLETED ✓", style: GoogleFonts.kanit(
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w700,
                            fontSize: 14, letterSpacing: 2)),
                      ),
                    ),

                  const SizedBox(height: 48),

                  // ▌ NOTES — Clean input
                  Text("NOTES", style: GoogleFonts.kanit(
                      fontSize: 11, color: _gold,
                      letterSpacing: 4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 5,
                    style: GoogleFonts.kanit(color: _textMain, fontSize: 14, height: 1.6),
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
                  Text("ATTACHMENTS", style: GoogleFonts.kanit(
                      fontSize: 11, color: _gold,
                      letterSpacing: 4, fontWeight: FontWeight.w700)),
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
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _bgSidebar,
                                  border: Border.all(color: _border.withOpacity(0.5)),
                                  image: DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(e.value.path) as ImageProvider
                                        : FileImage(File(e.value.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2, right: 2,
                                child: InkWell(
                                  onTap: () => setState(() => _attachedImages.removeAt(e.key)),
                                  child: Container(
                                    width: 20, height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
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
                          Text("ATTACH PHOTO", style: GoogleFonts.kanit(
                              fontSize: 11, color: _textMuted.withOpacity(0.4),
                              letterSpacing: 2, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("SAVE NOTE", style: GoogleFonts.kanit(
                          color: _gold, fontWeight: FontWeight.w600,
                          fontSize: 12, letterSpacing: 2)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.kanit(
                fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _card({
    String? title,
    Widget? child,
    bool expand = false,
    double padding = 24,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textMain)),
            const SizedBox(height: 20),
          ],
          if (child != null) expand ? Expanded(child: child) : child,
        ],
      ),
    );
  }

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

  Widget _techWorkCard(Map<String, dynamic> t) {
    String category = t['category'] ?? "General";

    Color statusColor = const Color(0xFFF59E0B); // Pending (Gold)
    if (t['uiStatus'] == 'working') statusColor = const Color(0xFF10B981); // Working (Green)
    if (t['uiStatus'] == 'done') statusColor = const Color(0xFF3B82F6); // Done (Blue)
    if (t['uiStatus'] == 'urgent') statusColor = const Color(0xFFFF3333); // Urgent (Red)

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
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2))),
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
                  Text((t['statusText'] ?? "PENDING").toUpperCase(),
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
                      width: 24, height: 4,
                      color: statusColor,
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                    Text(t['title'] ?? "Task",
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
                        Icon(Icons.location_on_rounded, size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text("${t['house']}",
                            style: GoogleFonts.kanit(
                                fontSize: 13, color: _textMuted, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text("${t['date']}",
                            style: GoogleFonts.kanit(
                                fontSize: 12, color: _textMuted.withOpacity(0.6))),
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
                border: Border(top: BorderSide(color: _border.withOpacity(0.3))),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("START WORK",
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.kanit(color: _textMuted)),
          ),
          Text(value, style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
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
                        ? (i == steps.length - 1 ? const Color(0xFF10B981) : _gold)
                        : (isActive ? _gold.withOpacity(0.15) : Colors.transparent),
                    border: Border.all(
                        color: s.done
                            ? Colors.transparent
                            : (isActive ? _gold : _border),
                        width: 2),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)]
                        : [],
                  ),
                  child: s.done
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : (isActive
                          ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: _gold, shape: BoxShape.circle)))
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
                      style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StepData {
  final String title;
  final String sub;
  final bool done;
  _StepData(this.title, this.sub, this.done);
}
