import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/data/repair_repository.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class TaskAssignmentOverlay extends StatefulWidget {
  final RepairRequest task;
  final List<String> draftStaffNames;
  final List<Map<String, dynamic>> technicians;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final VoidCallback onAbort;

  const TaskAssignmentOverlay({
    super.key,
    required this.task,
    required this.draftStaffNames,
    required this.technicians,
    required this.onDismiss,
    required this.onConfirm,
    required this.onAbort,
  });

  @override
  State<TaskAssignmentOverlay> createState() => _TaskAssignmentOverlayState();
}

class _TaskAssignmentOverlayState extends State<TaskAssignmentOverlay> {
  final TextEditingController _denialReasonController = TextEditingController();
  String? _selectedDenialTemplate;

  RepairTask? _focusedTask;

  @override
  void initState() {
    super.initState();
    _setupJsInterop();
  }

  @override
  void dispose() {
    _denialReasonController.dispose();
    super.dispose();
  }

  void _setupJsInterop() {
    try {
      js.context.callMethod('eval', [
        r"""
        (function() {
          // Helper: get Three.js scene from model-viewer internal
          const getScene = (mv) => {
            // Official: mv.model is a ThreeJS object hierarchy
            if (mv.model) return mv.model;
            // Fallback: search internal symbols
            const syms = Object.getOwnPropertySymbols(mv);
            for (const s of syms) {
              const v = mv[s];
              if (v && typeof v === 'object') {
                if (v.type === 'Scene' || v.scene?.type === 'Scene') return v.scene || v;
              }
            }
            return null;
          };

          // Dump all node names to console (for discovering correct mesh names)
          window.dumpModelNodes = function() {
            document.querySelectorAll('model-viewer').forEach((mv, idx) => {
              const scene = getScene(mv);
              if (!scene) { console.log('[FCM] mv #' + idx + ' scene not ready'); return; }
              const names = [];
              scene.traverse(n => { if (n.name) names.push(n.name); });
              console.log('[FCM] mv #' + idx + ' nodes:', names.join(', '));
            });
          };

          // Toggle shell visibility
          // show=true  → show roof+walls (exterior view)
          // show=false → hide roof+walls (interior view)
          window.toggleShell = function(show) {
            const mvs = document.querySelectorAll('model-viewer');
            if (!mvs.length) { console.warn('[FCM] no model-viewer found'); return; }
            mvs.forEach((mv, idx) => {
              const doToggle = () => {
                const scene = getScene(mv);
                if (!scene) { console.warn('[FCM] scene not available for mv #' + idx); return; }
                let toggled = 0;
                scene.traverse(node => {
                  const nm = (node.name || '').toLowerCase().trim();
                  // Roof: match any node with 'roof' or typical roof mesh names
                  const isRoof = nm.includes('roof') || nm.includes('hata') ||
                                 nm.includes('mai') || nm.includes('tile') ||
                                 nm.includes('cube032') || nm.includes('cube.032');
                  // Exterior walls: broad match for plane-based walls
                  const isWall = nm.includes('wall') || nm.includes('facade') ||
                                 nm.includes('exterior') || nm.includes('outside') ||
                                 nm.startsWith('plane.77') || nm.startsWith('plane.00') ||
                                 nm.startsWith('plane77')  || nm.startsWith('plane00');
                  if (isRoof || isWall) {
                    node.visible = show;
                    toggled++;
                  }
                });
                console.log('[FCM] toggleShell(show=' + show + '): toggled ' + toggled + ' nodes');
                // If nothing was toggled, dump names to help debug
                if (toggled === 0) window.dumpModelNodes();
              };

              // If model is already loaded, toggle immediately; otherwise wait
              if (mv.loaded) {
                doToggle();
              } else {
                mv.addEventListener('load', doToggle, { once: true });
              }
            });
          };
        })();
        """
      ]);
    } catch (e) {
      debugPrint("FCM JS Init Error: $e");
    }
  }

  void _showDenialOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "DENIAL_REASON",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: DashboardTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: DashboardTheme.error.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 40),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "DENY SERVICE REQUEST",
                            style: GoogleFonts.notoSans(
                                color: DashboardTheme.error,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                color: DashboardTheme.textPale),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "REASON FOR DENIAL (REQUIRED)",
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.textPale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: DashboardTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DashboardTheme.border),
                        ),
                        child: TextField(
                          controller: _denialReasonController,
                          maxLines: 4,
                          style: GoogleFonts.notoSans(
                              color: DashboardTheme.textMain, fontSize: 13),
                          onChanged: (val) => setLocalState(() {}),
                          decoration: InputDecoration(
                            hintText: "Specify reason for the resident...",
                            hintStyle: GoogleFonts.notoSans(
                                color: DashboardTheme.textPale, fontSize: 13),
                            contentPadding: const EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "SELECT TEMPLATE:",
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.textPale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildDenyTemplate(
                        "OUT_OF_SCOPE",
                        "❌ Outside project responsibility scope",
                        setLocalState,
                      ),
                      const SizedBox(height: 8),
                      _buildDenyTemplate(
                        "HARDWARE_OK",
                        "⚠️ Hardware operational / Improper usage",
                        setLocalState,
                      ),
                      const SizedBox(height: 8),
                      _buildDenyTemplate(
                        "UNCLEAR_DATA",
                        "📝 Insufficient or conflicting request details",
                        setLocalState,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
                              onPressed: _denialReasonController.text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : () async {
                                      bool success = await RepairRepository.instance.rejectRequest(
                                        widget.task.id,
                                        _denialReasonController.text,
                                        template: _selectedDenialTemplate,
                                      );
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                      if (success) {
                                        widget.onAbort();
                                      } else {
                                        // Still abort to close overlay in case of failure or just show error
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('เกิดข้อผิดพลาดในการปฏิเสธคำขอ'))
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.error,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text("CONFIRM DENIAL",
                                  style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
              scale: anim1.drive(CurveTween(curve: Curves.easeOutBack)),
              child: child),
        );
      },
    );
  }

  Widget _buildDenyTemplate(
      String id, String label, StateSetter setLocalState) {
    final bool isSelected = _selectedDenialTemplate == id;
    return InkWell(
      onTap: () {
        setLocalState(() {
          _selectedDenialTemplate = id;
          _denialReasonController.text =
              label.substring(label.indexOf(" ") + 1);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? DashboardTheme.error.withOpacity(0.12)
              : DashboardTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? DashboardTheme.error.withOpacity(0.4)
                  : Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            color: isSelected
                ? DashboardTheme.error
                : DashboardTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showLargeImage(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.black.withOpacity(0.9),
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: assetPath,
                  child: InteractiveViewer(
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 40,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> attachments = widget.task.imagePaths;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur & Dismiss
          GestureDetector(
            onTap: widget.onDismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 80, bottom: 200), // Push up to clear Staff Dock
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 1000, maxHeight: 600),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: DashboardTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DashboardTheme.border),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 60,
                          spreadRadius: 0),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        // --- MISSION HEADER ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 32, 32, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  terminalText(
                                      "TASK OPERATIONAL_DOSSIER",
                                      fontSize: 9,
                                      color: DashboardTheme.primary,
                                      letterSpacing: 2),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "บ้านเลขที่ ${widget.task.requesterHouse ?? 'N/A'}"
                                            .toUpperCase(),
                                        style: GoogleFonts.outfit(
                                            color: DashboardTheme.textMain,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(width: 24),
                                      _buildInfoTag(
                                        label: "STATUS",
                                        value: widget.task.status.toUpperCase(),
                                        color: widget.task.status == "DONE" || widget.task.status == "COMPLETED"
                                            ? DashboardTheme.success
                                            : (widget.task.status == "URGENT" 
                                                ? DashboardTheme.error 
                                                : DashboardTheme.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Material(
                                color: DashboardTheme.surfaceSecondary,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: widget.onDismiss,
                                  icon: Icon(Icons.close_rounded,
                                      color: DashboardTheme.textMain, size: 24),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // SCROLLABLE BODY
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(40, 10, 40, 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LEFT: CONTENT
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.task.title,
                                            style: GoogleFonts.outfit(
                                                color: DashboardTheme.textMain,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2),
                                          ),
                                          const SizedBox(height: 12),
                                          terminalText(
                                              "ID: ${widget.task.id}   DATE: ${widget.task.date}",
                                              fontSize: 9,
                                              color: DashboardTheme.textPale),
                                          const SizedBox(height: 48),

                                          terminalText(
                                              "TASK OBJECT DETAILS",
                                              fontSize: 10,
                                              color: DashboardTheme.textPale,
                                              letterSpacing: 2),
                                          const SizedBox(height: 24),

                                          ...widget.task.tasks.map((task) {
                                            final isFocused =
                                                _focusedTask?.id == task.id;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 16),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _focusedTask = task;
                                                  });

                                                  // Hide shell (roof+walls) for interior tasks, show for roof tasks
                                                  final isRoofTask = task
                                                          .category
                                                          ?.toLowerCase()
                                                          .contains('roof') ??
                                                      false;
                                                  try {
                                                    js.context.callMethod(
                                                        'toggleShell',
                                                        [isRoofTask]);
                                                  } catch (e) {}
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  decoration: BoxDecoration(
                                                    color: isFocused
                                                        ? DashboardTheme.primary
                                                            .withOpacity(0.05)
                                                        : DashboardTheme
                                                            .surfaceSecondary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    border: Border.all(
                                                      color: isFocused
                                                          ? DashboardTheme
                                                              .primary
                                                          : DashboardTheme
                                                              .border
                                                              .withOpacity(0.2),
                                                      width: isFocused ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            isFocused
                                                                ? Icons
                                                                    .adjust_rounded
                                                                : Icons
                                                                    .build_circle_outlined,
                                                            size: 20,
                                                            color: isFocused
                                                                ? DashboardTheme
                                                                    .primary
                                                                : DashboardTheme
                                                                    .textPale,
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              "${task.category ?? 'Task'}: ${task.objectName ?? 'General'}"
                                                                  .toUpperCase(),
                                                              style: GoogleFonts
                                                                  .shareTechMono(
                                                                color: isFocused
                                                                    ? DashboardTheme
                                                                        .primary
                                                                    : DashboardTheme
                                                                        .textMain,
                                                                fontSize: 14,
                                                                letterSpacing:
                                                                    1,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        task.description,
                                                        style:
                                                            GoogleFonts.outfit(
                                                          color: DashboardTheme
                                                              .textSecondary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          _buildInfoTag(
                                                            label: "WARRANTY",
                                                            value: widget.task
                                                                    .isWarranty
                                                                ? "ACTIVE"
                                                                : "EXPIRED",
                                                            color: widget.task
                                                                    .isWarranty
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                          if (!widget
                                                              .task.isWarranty)
                                                            _buildInfoTag(
                                                              label: "EST. FEE",
                                                              value:
                                                                  "฿${(task.laborFee + task.partFee).toStringAsFixed(0)}",
                                                              color:
                                                                  DashboardTheme
                                                                      .primary,
                                                            ),
                                                          if (task.preferDate != null)
                                                            _buildInfoTag(
                                                              label: "PREFER DATE",
                                                              value:
                                                                  "${task.preferDate!.day.toString().padLeft(2, '0')}/${task.preferDate!.month.toString().padLeft(2, '0')}/${task.preferDate!.year} ${task.preferDate!.hour.toString().padLeft(2, '0')}:${task.preferDate!.minute.toString().padLeft(2, '0')}",
                                                              color:
                                                                  DashboardTheme
                                                                      .success,
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),

                                          const SizedBox(height: 40),

                                          // Requester Info
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: DashboardTheme
                                                  .surfaceSecondary,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: DashboardTheme.border),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ClipOval(
                                                  child: Container(
                                                    width: 44,
                                                    height: 44,
                                                    color: DashboardTheme
                                                        .background,
                                                    child: Icon(Icons.person,
                                                        color: DashboardTheme
                                                            .primary,
                                                        size: 20),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    terminalText("REQUESTED_BY",
                                                        fontSize: 9,
                                                        color: DashboardTheme
                                                            .textPale),
                                                    Text(
                                                        widget.task
                                                                .requesterName ??
                                                            'RESIDENT',
                                                        style: GoogleFonts.notoSans(
                                                            color:
                                                                DashboardTheme
                                                                    .textMain,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // FOOTAGE SECTION (INITIAL)
                                if (attachments.isNotEmpty) ...[
                                  const SizedBox(height: 80),
                                  terminalText(
                                      "SECURED_EVIDENCE // ATTACHMENTS",
                                      fontSize: 10,
                                      color: DashboardTheme.textPale,
                                      letterSpacing: 2),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 180,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: attachments.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 24),
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () => _showLargeImage(
                                              context, attachments[index]),
                                          child: Hero(
                                            tag: attachments[index],
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: Container(
                                                width: 300,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: DashboardTheme
                                                          .border),
                                                ),
                                                child: Image.asset(
                                                  attachments[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],

                                // POST-MAINTENANCE SECTION
                                if (widget.task.techReport != null || widget.task.techReportPhotos.isNotEmpty) ...[
                                  const SizedBox(height: 80),
                                  terminalText(
                                      "POST_MAINTENANCE_LOG // FIELD_REPORT",
                                      fontSize: 10,
                                      color: DashboardTheme.success,
                                      letterSpacing: 2),
                                  const SizedBox(height: 24),
                                  if (widget.task.techReport != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: DashboardTheme.success.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: DashboardTheme.success.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          widget.task.techReport!,
                                          style: GoogleFonts.notoSans(
                                              color: DashboardTheme.textSecondary,
                                              fontSize: 14,
                                              height: 1.6),
                                        ),
                                      ),
                                    ),
                                  if (widget.task.techReportPhotos.isNotEmpty)
                                    SizedBox(
                                      height: 180,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: widget.task.techReportPhotos.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 24),
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => GestureDetector(
                                                  onTap: () => Navigator.pop(ctx),
                                                  child: Container(
                                                    color: Colors.black.withOpacity(0.9),
                                                    child: Image.network(
                                                      widget.task.techReportPhotos[index],
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (c, e, s) => const Center(
                                                          child: Icon(Icons.broken_image,
                                                              color: Colors.white24, size: 48)),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(24),
                                              child: Container(
                                                width: 300,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: DashboardTheme.border),
                                                ),
                                                child: Image.network(
                                                  widget.task.techReportPhotos[index],
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (c, child, progress) {
                                                    if (progress == null) return child;
                                                    return const Center(child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (c, e, s) => const Center(
                                                      child: Icon(Icons.broken_image,
                                                          color: Colors.white24)),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],

                                // ASSESSMENT SECTION
                                if (widget.task.rating != null) ...[
                                  const SizedBox(height: 80),
                                  terminalText(
                                      "RESIDENT_ASSESSMENT // SATISFACTION_METRICS",
                                      fontSize: 10,
                                      color: DashboardTheme.accentAmber,
                                      letterSpacing: 2),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: DashboardTheme.accentAmber.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: DashboardTheme.accentAmber.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < widget.task.rating!
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              color: DashboardTheme.accentAmber,
                                              size: 28,
                                            );
                                          }),
                                        ),
                                        if (widget.task.assessmentComment != null && widget.task.assessmentComment!.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            widget.task.assessmentComment!,
                                            style: GoogleFonts.notoSans(
                                              color: DashboardTheme.textMain,
                                              fontSize: 15,
                                              fontStyle: FontStyle.italic,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // STICKY FOOTER ACTION
                        Container(
                          padding: const EdgeInsets.fromLTRB(40, 20, 40, 24),
                          decoration: BoxDecoration(
                            color: DashboardTheme.surface,
                            border: Border(
                                top: BorderSide(color: DashboardTheme.border)),
                          ),
                          child: widget.task.status == "DONE"
                              ? SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: widget.onDismiss,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DashboardTheme.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 28),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      "CLOSE_DOSSIER",
                                      style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 1),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (widget.draftStaffNames.isNotEmpty)
                                            widget.onConfirm();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              widget.draftStaffNames.isEmpty
                                                  ? DashboardTheme.surfaceSecondary
                                                  : DashboardTheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 28),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          widget.draftStaffNames.isEmpty
                                              ? "SELECT PERSONNEL TO START DEPLOYMENT"
                                              : "EXECUTE DEPLOYMENT PROTOCOL (${widget.draftStaffNames.length})",
                                          style: GoogleFonts.outfit(
                                              color: widget.draftStaffNames.isEmpty
                                                  ? DashboardTheme.textPale
                                                  : Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              letterSpacing: 1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 32),
                                    TextButton(
                                      onPressed: () => _showDenialOverlay(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 28),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: Text(
                                        "DENY_REQUEST",
                                        style: GoogleFonts.outfit(
                                            color:
                                                DashboardTheme.error.withOpacity(0.8),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(
      {required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.shareTechMono(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.outfit(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
