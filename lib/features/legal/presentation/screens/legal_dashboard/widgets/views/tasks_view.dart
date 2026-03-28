import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_stats_widgets.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/widgets/technician_card.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/personnel_dossier_overlay.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/task_assignment_overlay.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/shared/widgets/pin_verification_overlay.dart';
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



class _TasksViewState extends State<TasksView> {
  String _taskFilter = "ALL";
  RepairRequest? _selectedTask;
  Map<String, dynamic>? _selectedTech;
  List<String> _draftStaffNames = [];

  late Timer _urgentTimer;

  @override
  void initState() {
    super.initState();
    _urgentTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        // Timer kept for potential future use or decoupling, but index increment removed
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
    return ValueListenableBuilder<List<RepairRequest>>(
      valueListenable: RepairRepository.instance.repairsNotifier,
      builder: (context, repairs, child) {
        final filteredTasks = repairs.where((r) {
          if (_taskFilter == "ALL") return true;

          bool isUrgent = r.isEmergency ||
              r.status == "URGENT" ||
              r.tasks.any((t) => t.urgency.toUpperCase() == "URGENT");

          if (_taskFilter == "URGENT") return isUrgent;

          String mappedStatus = "PENDING";
          if (r.status == "COMPLETED" || r.status == "EVALUATED") {
            mappedStatus = "DONE";
          } else if (r.status == "IN PROGRESS") {
            mappedStatus = "WORKING";
          } else if (r.status == "REJECTED" ||
              r.status == "DENIED" ||
              r.status == "DECLINED") {
            mappedStatus = "DENIED";
          } else if (r.status == "CREATED" ||
              r.status == "AWAITING APPROVAL" ||
              r.status == "PENDING" ||
              r.status == "ASSIGNED") {
            mappedStatus = "PENDING";
          }
          return mappedStatus == _taskFilter;
        }).toList();

        final int totalCount = repairs.length;
        final int urgentCount = repairs
            .where((r) =>
                r.isEmergency ||
                r.status == "URGENT" ||
                r.tasks.any((t) => t.urgency.toUpperCase() == "URGENT"))
            .length;
        final int pendingCount = repairs
            .where((r) =>
                r.status == "PENDING" ||
                r.status == "CREATED" ||
                r.status == "AWAITING APPROVAL" ||
                r.status == "ASSIGNED")
            .length;
        final int workingCount =
            repairs.where((r) => r.status == "IN PROGRESS").length;
        final int doneCount =
            repairs.where((r) => r.status == "COMPLETED" || r.status == "EVALUATED").length;
        final int deniedCount = repairs
            .where((r) =>
                r.status == "REJECTED" ||
                r.status == "DENIED" ||
                r.status == "DECLINED")
            .length;

        // filteredTasks is already defined above

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
                                terminalText(
                                    "ผู้ดูแลระบบ // จัดการรายการแจ้งซ่อม",
                                    fontSize: 10,
                                    color:
                                        DashboardTheme.primary.withOpacity(0.5),
                                    letterSpacing: 1.5),
                                const SizedBox(height: 12),
                                Text(
                                  "รายการแจ้งซ่อม",
                                  style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textMain,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 50),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              // Only keep Satisfaction Score as requested
                              SizedBox(
                                width: 280,
                                child: MetricCard(
                                  label: "คะแนนความพึงพอใจ",
                                  icon: Icons.star_rate_rounded,
                                  color: DashboardTheme.accentAmber,
                                  onTap: () {
                                    final ratedRepairs = repairs
                                        .where((r) =>
                                            r.rating != null && r.rating! > 0)
                                        .toList();
                                    final avgRating = ratedRepairs.isEmpty
                                        ? 0.0
                                        : ratedRepairs.fold(0.0,
                                                (sum, r) => sum + r.rating!) /
                                            ratedRepairs.length;

                                    showDashboardOverlay(
                                      context: context,
                                      title: "ความพึงพอใจ",
                                      subtitle: "ค่าเฉลี่ยจากลูกบ้าน",
                                      icon: Icons.star_rounded,
                                      color: DashboardTheme.accentAmber,
                                      content: DashboardStatsWidgets
                                          .buildRatingExpanded(
                                              context, avgRating, ratedRepairs),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(5, (index) {
                                          final ratedRepairs = repairs
                                              .where((r) =>
                                                  r.rating != null &&
                                                  r.rating! > 0)
                                              .toList();
                                          final currentRating = ratedRepairs
                                                  .isEmpty
                                              ? 0.0
                                              : ratedRepairs.fold(
                                                      0.0,
                                                      (sum, r) =>
                                                          sum + r.rating!) /
                                                  ratedRepairs.length;
                                          return Icon(
                                            index < currentRating.floor()
                                                ? Icons.star_rounded
                                                : (index < currentRating
                                                    ? Icons.star_half_rounded
                                                    : Icons
                                                        .star_outline_rounded),
                                            color: DashboardTheme.accentAmber,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 6),
                                      Builder(builder: (context) {
                                        final ratedRepairs = repairs
                                            .where((r) =>
                                                r.rating != null &&
                                                r.rating! > 0)
                                            .toList();
                                        final currentRating = ratedRepairs
                                                .isEmpty
                                            ? 0.0
                                            : ratedRepairs.fold(
                                                    0.0,
                                                    (sum, r) =>
                                                        sum + r.rating!) /
                                                ratedRepairs.length;
                                        return Text(
                                            "${currentRating.toStringAsFixed(1)} / 5.0",
                                            style: GoogleFonts.notoSans(
                                                color: DashboardTheme.textMain,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800));
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                              // Removed Full Stats action card
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: DashboardTheme.surface,
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(32)),
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
                                  border:
                                      Border.all(color: DashboardTheme.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('filter_all'),
                                        totalCount.toString(),
                                        _taskFilter == "ALL",
                                        () => setState(
                                            () => _taskFilter = "ALL")),
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('type_urgent'),
                                        urgentCount.toString(),
                                        _taskFilter == "URGENT",
                                        () => setState(
                                            () => _taskFilter = "URGENT")),
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('status_created'),
                                        pendingCount.toString(),
                                        _taskFilter == "PENDING",
                                        () => setState(
                                            () => _taskFilter = "PENDING")),
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('status_began'),
                                        workingCount.toString(),
                                        _taskFilter == "WORKING",
                                        () => setState(
                                            () => _taskFilter = "WORKING")),
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('status_completed'),
                                        doneCount.toString(),
                                        _taskFilter == "DONE",
                                        () => setState(
                                            () => _taskFilter = "DONE")),
                                    _buildModernTab(
                                        TranslationService.instance
                                            .t('status_declined'),
                                        deniedCount.toString(),
                                        _taskFilter == "DENIED",
                                        () => setState(
                                            () => _taskFilter = "DENIED")),
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
                              separatorBuilder: (_, __) => Divider(
                                  color: DashboardTheme.border, height: 1),
                              itemBuilder: (context, index) =>
                                  _buildModernTableRow(filteredTasks[index]),
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
                    technicians: widget.technicians
                        .where((t) => t['role'] == 'TECHNICIAN')
                        .toList(),
                    onDismiss: () => setState(() {
                      _selectedTask = null;
                      _draftStaffNames = [];
                    }),
                    onConfirm: () async {
                      if (_draftStaffNames.isNotEmpty) {
                        // PIN verification before assigning
                        final pinOk = await showPinVerificationOverlay(context);
                        if (pinOk != true) return;

                        bool success = await RepairRepository.instance
                            .assignRequest(_selectedTask!.id, _draftStaffNames);
                        if (mounted) {
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('เกิดข้อผิดพลาดในการมอบหมายงาน')));
                          }
                        }
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
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 210,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widget.technicians
                                  .where((tech) => tech['role'] == 'TECHNICIAN')
                                  .map<Widget>((tech) {
                                return TechnicianCard(
                                  name: tech['name'],
                                  status: (tech['isActive'] ?? true)
                                      ? "ACTIVE"
                                      : "INACTIVE",
                                  statusColor: (tech['isActive'] ?? true)
                                      ? DashboardTheme.success
                                      : DashboardTheme.accentAmber,
                                  isActive: tech['isActive'] ?? true,
                                  isSelected:
                                      _draftStaffNames.contains(tech['name']),
                                  imagePath: tech['image'],
                                  roleIcon: tech['role'] == 'JURISTIC'
                                      ? Icons.admin_panel_settings_rounded
                                      : Icons.engineering_rounded,
                                  role: tech['role'],
                                  onTap: () {
                                    if (_selectedTask != null &&
                                        (tech['isActive'] ?? true)) {
                                      setState(() {
                                        if (_draftStaffNames
                                            .contains(tech['name'])) {
                                          _draftStaffNames.remove(tech['name']);
                                        } else {
                                          _draftStaffNames.add(tech['name']);
                                        }
                                      });
                                    }
                                  },
                                );
                              }).toList(),
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
      },
    );
  }


  Widget _buildModernTab(
      String label, String count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? DashboardTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive
                  ? DashboardTheme.primary.withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSans(
                color:
                    isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? DashboardTheme.primary
                    : DashboardTheme.surfaceSecondary,
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
          _tableHeaderCell("วันที่แจ้ง", flex: 2),
          _tableHeaderCell("เรื่อง", flex: 5),
          _tableHeaderCell("ผู้แจ้ง", flex: 3),
          _tableHeaderCell("บ้านเลขที่", flex: 3),
          _tableHeaderCell("ผู้รับผิดชอบ", flex: 3),
          _tableHeaderCell("สถานะ", flex: 2),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label,
      {int flex = 1, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: terminalText(label,
            fontSize: 10,
            color: DashboardTheme.textPale,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModernTableRow(RepairRequest task) {
    String mappedStatus = "PENDING";
    if (task.status == "EVALUATED")
      mappedStatus = "EVALUATED";
    else if (task.status == "COMPLETED")
      mappedStatus = "DONE";
    else if (task.status == "URGENT" ||
        task.isEmergency ||
        task.tasks.any((t) => t.urgency.toUpperCase() == "URGENT"))
      mappedStatus = "URGENT";
    else if (task.status == "IN PROGRESS")
      mappedStatus = "WORKING";
    else if (task.status == "CREATED")
      mappedStatus = "CREATED";
    else if (task.status == "ASSIGNED")
      mappedStatus = "ASSIGNED";
    else if (task.status == "PENDING")
      mappedStatus = "PENDING";
    else if (task.status == "DECLINED")
      mappedStatus = "DECLINED";
    else if (task.status == "REJECTED" || task.status == "DENIED")
      mappedStatus = "DENIED";
    else if (task.status == "CANCELLED") mappedStatus = "CANCELLED";

    final status = mappedStatus;
    Color statusColor = DashboardTheme.accentAmber;
    if (status == "URGENT") statusColor = DashboardTheme.error;
    if (status == "CREATED") statusColor = DashboardTheme.primary;
    if (status == "ASSIGNED")
      statusColor = DashboardTheme.primary.withOpacity(0.8);
    if (status == "PENDING") statusColor = DashboardTheme.warning;
    if (status == "WORKING") statusColor = DashboardTheme.success;
    if (status == "DONE") statusColor = const Color(0xFF6366F1);
    if (status == "EVALUATED") statusColor = DashboardTheme.success;
    if (status == "DECLINED" || status == "DENIED")
      statusColor = DashboardTheme.error;

    String statusText = status;
    if (status == "URGENT")
      statusText = TranslationService.instance.t('type_urgent');
    if (status == "CREATED")
      statusText = TranslationService.instance.t('status_created');
    if (status == "ASSIGNED")
      statusText = TranslationService.instance.t('status_assigned');
    if (status == "WORKING")
      statusText = TranslationService.instance.t('status_began');
    if (status == "DONE")
      statusText = TranslationService.instance.t('status_completed');
    if (status == "EVALUATED")
      statusText = TranslationService.instance.t('status_evaluated');
    if (status == "DECLINED")
      statusText = TranslationService.instance.t('status_declined');
    if (status == "DENIED")
      statusText = TranslationService.instance.t('status_declined');
    if (status == "CANCELLED")
      statusText = TranslationService.instance.t('status_canceled');

    final bool isInteractive = status == "CREATED" ||
        status == "PENDING" ||
        status == "URGENT" ||
        status == "ASSIGNED" ||
        status == "DONE" ||
        status == "EVALUATED";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive
            ? () {
                setState(() {
                  _selectedTask = task;
                  _draftStaffNames = List<String>.from(task.assignedStaff);
                });
              }
            : null,
        mouseCursor:
            isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        hoverColor: statusColor.withOpacity(0.04),
        highlightColor: statusColor.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: 2,
                child: terminalText(task.date.isNotEmpty ? task.date : task.id,
                    fontSize: 11,
                    color: DashboardTheme.textSecondary,
                    fontWeight: FontWeight.bold),
              ),
              // Title & Report
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: task.statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.handyman_rounded,
                          color: task.statusColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (task.isEmergency ||
                                  task.tasks.any((t) =>
                                      t.urgency.toUpperCase() == "URGENT")) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        DashboardTheme.error.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: DashboardTheme.error
                                            .withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    TranslationService.instance
                                        .t('type_urgent'),
                                    style: GoogleFonts.notoSans(
                                      color: DashboardTheme.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: GoogleFonts.notoSans(
                                      color: DashboardTheme.textMain,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      height: 1.4),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            style: GoogleFonts.notoSans(
                                color: DashboardTheme.textPale,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
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
                      backgroundColor: DashboardTheme.border,
                      child: Icon(Icons.person,
                          size: 9, color: DashboardTheme.textPale),
                    ),
                    const SizedBox(width: 8),
                    terminalText(
                        task.requesterName ?? task.requesterEmail ?? "@unknown",
                        fontSize: 11,
                        color: DashboardTheme.textSecondary),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(task.requesterHouse ?? "FACILITY",
                    style: GoogleFonts.shareTechMono(
                        color: DashboardTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  task.assignedStaff.isNotEmpty
                      ? task.assignedStaff.join(", ")
                      : "UNASSIGNED",
                  style: GoogleFonts.shareTechMono(
                    color: task.assignedStaff.isNotEmpty
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.shareTechMono(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
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
            Text(preset.name,
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: DashboardTheme.error.withOpacity(0.6), size: 20),
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
              Text("สมาชิก ${preset.memberNames.length} คน",
                  style: GoogleFonts.notoSans(
                      color: DashboardTheme.textPale, fontSize: 12)),
              const SizedBox(height: 12),
              ...preset.memberNames.map((name) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded,
                            color: DashboardTheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(name,
                            style: GoogleFonts.notoSans(
                                color: DashboardTheme.textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ปิด",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.bold)),
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
            Icon(Icons.folder_special_rounded,
                color: DashboardTheme.primary, size: 24),
            const SizedBox(width: 12),
            Text("SAVE TEAM PRESET",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Members: ${_draftStaffNames.join(', ')}",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.notoSans(
                  color: DashboardTheme.textMain, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Team name...",
                hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale),
                filled: true,
                fillColor: DashboardTheme.surfaceSecondary,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: DashboardTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: DashboardTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: DashboardTheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("SAVE",
                style: GoogleFonts.notoSans(
                    color: Colors.white, fontWeight: FontWeight.w900)),
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
        title: Text("DELETE PRESET?",
            style: GoogleFonts.notoSans(
                color: DashboardTheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
        content: Text("Remove team preset \"${preset.name}\"?",
            style: GoogleFonts.notoSans(
                color: DashboardTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              RepairRepository.instance.deleteTeamPreset(preset.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("DELETE",
                style: GoogleFonts.notoSans(
                    color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
