import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_stats_widgets.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/widgets/technician_card.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/personnel_dossier_overlay.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/task_assignment_overlay.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'dart:async';


class TasksView extends StatefulWidget {
  final List<Map<String, dynamic>> technicians;
  final Function(int) onIndexChanged;

  const TasksView({
    super.key,
    required this.technicians,
    required this.onIndexChanged,
  });

  @override
  State<TasksView> createState() => _TasksViewState();
}

enum RegistryTab { staffs, teams }

class _TasksViewState extends State<TasksView> {
  String _taskFilter = "ALL";
  Map<String, dynamic>? _selectedTask;
  Map<String, dynamic>? _selectedTech;
  List<String> _draftStaffNames = [];
  
  // Personnel Registry Selection Mode
  RegistryTab _personnelRegistryTab = RegistryTab.staffs;
  
  late Timer _urgentTimer;
  int _urgentIndex = 0;

  @override
  void initState() {
    super.initState();
    _urgentTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _urgentIndex++;
        });
      }
    });
  }

  @override
  void dispose() {
    _urgentTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = DashboardData.tasks;

    final int totalCount = allTasks.length;
    final int urgentCount = allTasks.where((t) => t['status'] == "URGENT").length;
    final int pendingCount = allTasks.where((t) => t['status'] == "PENDING").length;
    final int workingCount = allTasks.where((t) => t['status'] == "WORKING").length;
    final int doneCount = allTasks.where((t) => t['status'] == "DONE").length;
    final int deniedCount = allTasks.where((t) => t['status'] == "DENIED").length;

    const int totalHouses = 120;
    final activeIssueHouses = allTasks
        .where((t) => t['status'] != "DONE")
        .map((t) => t['house'] as String)
        .toSet()
        .length;
    final double healthScore = ((totalHouses - activeIssueHouses) / totalHouses) * 100;

    final urgentTasks = allTasks.where((t) => t['status'] == "URGENT").toList();
    final criticalTask = urgentTasks.isNotEmpty 
        ? urgentTasks[_urgentIndex % urgentTasks.length]
        : allTasks.firstWhere(
            (t) => t['status'] == "PENDING" && (t['icon'] == Icons.bolt || t['icon'] == Icons.water_drop),
            orElse: () => allTasks.firstWhere((t) => t['status'] != "DONE", orElse: () => allTasks[0]),
          );

    final filteredTasks = _taskFilter == "ALL" 
        ? allTasks 
        : allTasks.where((t) => t['status'] == _taskFilter).toList();

    return Container(
      color: DashboardTheme.background,
      child: Stack(
        children: [
          Column(
            children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 90, 28, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        terminalText("SYS.ADMIN // SERVICE REQUEST AUDIT", fontSize: 10, color: DashboardTheme.primary.withOpacity(0.5), letterSpacing: 1.5),
                        const SizedBox(height: 12),
                        Text(
                          "Service Requests",
                          style: GoogleFonts.notoSans(
                            color: DashboardTheme.textMain,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 340,
                          height: 44,
                          decoration: BoxDecoration(
                            color: DashboardTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DashboardTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: TextField(
                            style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 13),
                            cursorColor: DashboardTheme.primary,
                            decoration: InputDecoration(
                              hintText: "Search requests, ID or unit...",
                              hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale),
                              prefixIcon: Icon(Icons.search_rounded, color: DashboardTheme.textPale, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    MetricCard(
                      label: "Success Rate",
                      icon: Icons.track_changes_rounded,
                      color: DashboardTheme.success,
                      onTap: () {
                        final allTasks = DashboardData.tasks;
                        final doneCount = allTasks.where((t) => t['status'] == "DONE").length;
                        final totalHistorical = 4281;
                        final resolvedHistorical = 4127;
                        final globalVolumeTotal = totalHistorical + allTasks.length;
                        final resolvedTotal = resolvedHistorical + doneCount;
                        final successRate = (resolvedTotal / globalVolumeTotal);

                        showDashboardOverlay(
                          context: context,
                          title: "SUCCESS RATE",
                          subtitle: "LIFETIME RESOLUTION DELTA",
                          icon: Icons.track_changes_rounded,
                          color: DashboardTheme.primary,
                          content: DashboardStatsWidgets.buildSuccessExpanded(context, successRate),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("94.2%", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.942,
                              backgroundColor: DashboardTheme.border,
                              valueColor: AlwaysStoppedAnimation<Color>(DashboardTheme.success),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    MetricCard(
                      label: "Village Health",
                      icon: Icons.shield_rounded,
                      color: DashboardTheme.primary,
                      onTap: () {
                        final allTasks = DashboardData.tasks;
                        final urgentCount = allTasks.where((t) => t['status'] == "URGENT").length;
                        final pendingCount = allTasks.where((t) => t['status'] == "PENDING").length;
                        final workingCount = allTasks.where((t) => t['status'] == "WORKING").length;
                        final healthScore = (100 - (urgentCount * 5 + pendingCount * 2 + workingCount * 1)).clamp(0, 100).toDouble();

                        showDashboardOverlay(
                          context: context,
                          title: "VILLAGE HEALTH",
                          subtitle: "STRUCTURAL & SYSTEM INTEGRITY",
                          icon: Icons.shield_rounded,
                          color: DashboardTheme.primary,
                          content: DashboardStatsWidgets.buildHealthExpanded(context, healthScore, urgentCount, pendingCount),
                        );
                      },
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: healthScore / 100,
                                  strokeWidth: 4,
                                  backgroundColor: DashboardTheme.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(DashboardTheme.primary),
                                ),
                                Text("${healthScore.toInt()}%", style: GoogleFonts.shareTechMono(color: DashboardTheme.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text("Safe Zone", style: GoogleFonts.notoSans(color: DashboardTheme.primary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    MetricCard(
                      label: "Critical Focus",
                      icon: Icons.notification_important_rounded,
                      color: DashboardTheme.error,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          key: ValueKey<String>("${criticalTask['id']}"),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: DashboardTheme.error.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DashboardTheme.error.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: DashboardTheme.error, size: 18),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("RESIDENT ${criticalTask['house']}", style: GoogleFonts.shareTechMono(color: DashboardTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(criticalTask['title'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.error.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    MetricCard(
                      label: "User Ratings",
                      icon: Icons.star_rate_rounded,
                      color: DashboardTheme.accentAmber,
                      onTap: () => showDashboardOverlay(
                        context: context,
                        title: "USER SATISFACTION",
                        subtitle: "RESIDENT FEEDBACK AVG",
                        icon: Icons.star_rounded,
                        color: DashboardTheme.accentAmber,
                        content: DashboardStatsWidgets.buildRatingExpanded(context, DashboardData.calculatedAvgRating),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              final currentRating = DashboardData.calculatedAvgRating;
                              return Icon(
                                index < currentRating.floor() ? Icons.star_rounded : (index < currentRating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                color: DashboardTheme.accentAmber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${DashboardData.calculatedAvgRating.toStringAsFixed(1)} / 5.0", 
                            style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w800)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onIndexChanged(5),
                        borderRadius: BorderRadius.circular(20),
                        hoverColor: DashboardTheme.primary.withOpacity(0.04),
                        child: Ink(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: DashboardTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: DashboardTheme.border),
                            boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_forward_rounded, color: DashboardTheme.primary),
                              const SizedBox(height: 8),
                              terminalText("FULL\nSTATS", fontSize: 10, fontWeight: FontWeight.bold, color: DashboardTheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: DashboardTheme.surface,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: DashboardTheme.border),
                  right: BorderSide(color: DashboardTheme.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  )
                ],
              ),
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: DashboardTheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DashboardTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModernTab("All", "$totalCount", _taskFilter == "ALL", () => setState(() => _taskFilter = "ALL")),
                            _buildModernTab("Urgent", "$urgentCount", _taskFilter == "URGENT", () => setState(() => _taskFilter = "URGENT")),
                            _buildModernTab("Pending", "$pendingCount", _taskFilter == "PENDING", () => setState(() => _taskFilter = "PENDING")),
                            _buildModernTab("Working", "$workingCount", _taskFilter == "WORKING", () => setState(() => _taskFilter = "WORKING")),
                            _buildModernTab("Completed", "$doneCount", _taskFilter == "DONE", () => setState(() => _taskFilter = "DONE")),
                            _buildModernTab("Denied", "$deniedCount", _taskFilter == "DENIED", () => setState(() => _taskFilter = "DENIED")),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ],
                    ),
                  const SizedBox(height: 24),

                  _buildTableHeader(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (_, __) => Divider(color: DashboardTheme.border, height: 1), 
                      itemBuilder: (context, index) => _buildModernTableRow(filteredTasks[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
          
      // --- SHARED OVERLAYS (DRAGGED FROM OVERVIEW) ---
          
          // 1. PERSONNEL DOSSIER
          if (_selectedTech != null)
            Positioned.fill(
              child: PersonnelDossierOverlay(
                technician: _selectedTech!,
                onDismiss: () => setState(() => _selectedTech = null),
              ),
            ),

          // 2. TASK ASSIGNMENT HUD
          if (_selectedTask != null)
            Positioned.fill(
              child: TaskAssignmentOverlay(
                task: _selectedTask!,
                draftStaffNames: _draftStaffNames,
                onDismiss: () => setState(() {
                  _selectedTask = null;
                  _draftStaffNames = [];
                }),
                onConfirm: () {
                  if (_draftStaffNames.isNotEmpty) {
                    _selectedTask!['staffNames'] = List<String>.from(_draftStaffNames);
                  }
                  setState(() {
                    _selectedTask = null;
                    _draftStaffNames = [];
                  });
                },
                onAbort: () => setState(() {
                  _selectedTask = null;
                  _draftStaffNames = [];
                }),
              ),
            ),

          // ── Staff Dock (only visible during assignment) ──
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _selectedTask != null ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: _selectedTask == null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── DOCK TABS ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: DashboardTheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DashboardTheme.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<List<TeamPreset>>(
                            valueListenable: RepairRepository.instance.teamPresetsNotifier,
                            builder: (context, presets, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildModernDockTab("บุคลากร", "${DashboardData.technicians.length}", _personnelRegistryTab == RegistryTab.staffs, () => setState(() => _personnelRegistryTab = RegistryTab.staffs)),
                                  _buildModernDockTab("ทีม", "${presets.length}", _personnelRegistryTab == RegistryTab.teams, () => setState(() => _personnelRegistryTab = RegistryTab.teams)),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 210,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _personnelRegistryTab == RegistryTab.staffs 
                            ? (DashboardData.technicians.map<Widget>((tech) {
                                return TechnicianCard(
                                  name: tech['name'],
                                  status: tech['isActive'] ? "ACTIVE" : "INACTIVE",
                                  statusColor: tech['isActive'] ? DashboardTheme.success : DashboardTheme.accentAmber,
                                  isActive: tech['isActive'],
                                  isSelected: _draftStaffNames.contains(tech['name']),
                                  imagePath: tech['image'],
                                  roleIcon: tech['icon'],
                                  role: tech['role'],
                                  onTap: () {
                                    if (_selectedTask != null && tech['isActive']) {
                                      setState(() {
                                        if (_draftStaffNames.contains(tech['name'])) {
                                          _draftStaffNames.remove(tech['name']);
                                        } else {
                                          _draftStaffNames.add(tech['name']);
                                        }
                                      });
                                    }
                                  },
                                );
                              }).toList())
                            : <Widget>[ValueListenableBuilder<List<TeamPreset>>(
                                valueListenable: RepairRepository.instance.teamPresetsNotifier,
                                builder: (context, presets, _) {
                                  if (presets.isEmpty) {
                                    return Center(child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40),
                                      child: Text("ยังไม่มีข้อมูลทีม", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13)),
                                    ));
                                  }
                                  return Row(
                                    children: presets.map((preset) {
                                      final bool allSelected = _selectedTask != null && preset.memberNames.every((n) => _draftStaffNames.contains(n));
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (allSelected) {
                                                _draftStaffNames.removeWhere((n) => preset.memberNames.contains(n));
                                              } else {
                                                for (final name in preset.memberNames) {
                                                  if (!_draftStaffNames.contains(name)) _draftStaffNames.add(name);
                                                }
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 180,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: DashboardTheme.surface,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: allSelected ? const Color(0xFF00E676) : DashboardTheme.border, width: 2),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(preset.icon, color: allSelected ? const Color(0xFF00E676) : DashboardTheme.primary, size: 28),
                                                const SizedBox(height: 12),
                                                Text(preset.name, style: GoogleFonts.notoSans(color: allSelected ? const Color(0xFF00E676) : DashboardTheme.textMain, fontSize: 15, fontWeight: FontWeight.w900)),
                                                const SizedBox(height: 6),
                                                Text("${preset.memberNames.length} Members", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              )],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDockTab(String label, String count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? DashboardTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? DashboardTheme.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? DashboardTheme.primary : DashboardTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count,
                style: GoogleFonts.shareTechMono(
                  color: isActive ? Colors.black : DashboardTheme.textPale,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTab(String label, String count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? DashboardTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? DashboardTheme.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? DashboardTheme.primary : DashboardTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count,
                style: GoogleFonts.shareTechMono(
                  color: isActive ? Colors.black : DashboardTheme.textPale,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Row(
        children: [
          _tableHeaderCell("ID", flex: 2),
          _tableHeaderCell("TITLE", flex: 5),
          _tableHeaderCell("REQUESTED BY", flex: 3),
          _tableHeaderCell("UNIT / LOC", flex: 3),
          _tableHeaderCell("ASSIGNED TO", flex: 3),
          _tableHeaderCell("STATUS", flex: 2),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label, {int flex = 1, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: terminalText(label, fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModernTableRow(Map<String, dynamic> task) {
    final status = task['status'] as String;
     Color statusColor = DashboardTheme.accentAmber;
    if (status == "URGENT") statusColor = DashboardTheme.error;
    if (status == "PENDING") statusColor = DashboardTheme.warning;
    if (status == "WORKING") statusColor = DashboardTheme.success;
    if (status == "DONE") statusColor = const Color(0xFF6366F1);
    if (status == "DENIED") statusColor = DashboardTheme.error;

    final bool isInteractive = status == "PENDING" || status == "URGENT";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? () {
          setState(() {
            _selectedTask = task;
            _draftStaffNames = List<String>.from(task['staffNames'] ?? []);
          });
        } : null,
        mouseCursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: statusColor.withOpacity(0.04),
        highlightColor: statusColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: 2,
                child: terminalText(task['id'] as String, fontSize: 11, color: DashboardTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
              // Title & Report
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (task['color'] as Color).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(task['icon'] as IconData, color: task['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] as String,
                            style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 13, fontWeight: FontWeight.w700, height: 1.4),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (task['report'] as String?) ?? "",
                            style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 10, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Requested By
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundImage: task['requesterImage'] != null ? AssetImage(task['requesterImage']) : null,
                      backgroundColor: DashboardTheme.border,
                      child: task['requesterImage'] == null ? Icon(Icons.person, size: 9, color: DashboardTheme.textPale) : null,
                    ),
                    const SizedBox(width: 8),
                    terminalText(task['requesterAccount'] ?? "@unknown", fontSize: 11, color: DashboardTheme.textSecondary),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(task['house'] as String, style: GoogleFonts.shareTechMono(color: DashboardTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  (task['staffNames'] != null && (task['staffNames'] as List).isNotEmpty)
                      ? (task['staffNames'] as List).join(", ")
                      : (task['staff'] ?? "UNASSIGNED"),
                  style: GoogleFonts.shareTechMono(
                    color: (task['staffNames'] != null && (task['staffNames'] as List).isNotEmpty) || task['staff'] != null 
                        ? DashboardTheme.textSecondary 
                        : DashboardTheme.textPale, 
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.shareTechMono(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Team Preset Dialogs ──

  void _showPresetMembersDialog(TeamPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(preset.icon, color: DashboardTheme.primary, size: 22),
            const SizedBox(width: 10),
            Text(preset.name, style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: DashboardTheme.error.withOpacity(0.6), size: 20),
              onPressed: () {
                Navigator.pop(ctx);
                _showDeletePresetDialog(preset);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("สมาชิก ${preset.memberNames.length} คน", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 12)),
              const SizedBox(height: 12),
              ...preset.memberNames.map((name) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, color: DashboardTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(name, style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ปิด", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.folder_special_rounded, color: DashboardTheme.primary, size: 24),
            const SizedBox(width: 12),
            Text("SAVE TEAM PRESET", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Members: ${_draftStaffNames.join(', ')}", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Team name...",
                hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale),
                filled: true,
                fillColor: DashboardTheme.surfaceSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                RepairRepository.instance.addTeamPreset(
                  name: controller.text.trim(),
                  memberNames: List.from(_draftStaffNames),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("SAVE", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeletePresetDialog(TeamPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("DELETE PRESET?", style: GoogleFonts.notoSans(color: DashboardTheme.error, fontSize: 16, fontWeight: FontWeight.w900)),
        content: Text("Remove team preset \"${preset.name}\"?", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              RepairRepository.instance.deleteTeamPreset(preset.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("DELETE", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
