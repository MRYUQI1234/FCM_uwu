import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_painters.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class TaskAssignmentOverlay extends StatefulWidget {
  final RepairRequest task;
  final List<String> draftStaffNames;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final VoidCallback onAbort;

  const TaskAssignmentOverlay({
    super.key,
    required this.task,
    required this.draftStaffNames,
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
  String _cameraTarget = '0m 1m 0m';
  String _cameraOrbit = '45deg 75deg 5m';
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
                                  : () {
                                      RepairRepository.instance.rejectRequest(
                                        widget.task.id,
                                        _denialReasonController.text,
                                        template: _selectedDenialTemplate,
                                      );
                                      Navigator.pop(context);
                                      widget.onAbort();
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
    final List<Map<String, dynamic>> selectedTechs = DashboardData.technicians
        .where(
          (t) => widget.draftStaffNames.contains(t['name']),
        )
        .toList();

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
                        // --- MISSION HEADER (NEW STYLE) ---
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
                                      "TASK // OPERATIONAL_DOSSIER // ACCESS_GRANTED",
                                      fontSize: 9,
                                      color: DashboardTheme.primary,
                                      letterSpacing: 2),
                                  const SizedBox(height: 8),
                                  Text(
                                    "บ้านเลขที่ ${widget.task.requesterHouse ?? 'N/A'}"
                                        .toUpperCase(),
                                    style: GoogleFonts.outfit(
                                        color: DashboardTheme.textMain,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900),
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
                                              "ID_PARAM: ${widget.task.id} // TIMESTAMP: ${widget.task.date}",
                                              fontSize: 9,
                                              color: DashboardTheme.textPale),
                                          const SizedBox(height: 48),

                                          terminalText(
                                              "TASK_OBJECT_DETAILS // INTERFACE",
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
                                                    _cameraTarget =
                                                        task.modelRef3D ??
                                                            '0m 1.5m 0m';
                                                    _cameraOrbit =
                                                        '0deg 90deg 3m';
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

                                    const SizedBox(width: 80),

                                    // RIGHT: DEPLOYMENT
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              terminalText("DEPLOYED_PERSONNEL",
                                                  fontSize: 10,
                                                  color:
                                                      DashboardTheme.textPale,
                                                  letterSpacing: 1),
                                              if (widget
                                                  .draftStaffNames.isNotEmpty)
                                                IconButton(
                                                  onPressed: () =>
                                                      _showSaveTeamDialog(
                                                          context),
                                                  icon: const Icon(
                                                      Icons.save_as_rounded,
                                                      size: 18),
                                                  color:
                                                      const Color(0xFF00E676),
                                                  tooltip: "บันทึกเป็น Preset",
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: selectedTechs
                                                .map((t) => Column(
                                                      children: [
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration:
                                                              BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: DashboardTheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 2),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(2),
                                                            child: ClipOval(
                                                                child: Image.asset(
                                                                    t['image'],
                                                                    fit: BoxFit
                                                                        .cover)),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        terminalText(
                                                            t['name']
                                                                .toString()
                                                                .toUpperCase(),
                                                            fontSize: 8,
                                                            color: DashboardTheme
                                                                .textSecondary,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ],
                                                    ))
                                                .toList(),
                                          ),
                                          if (selectedTechs.isEmpty)
                                            Text("AWAITING_ASSIGNMENT...",
                                                style:
                                                    GoogleFonts.shareTechMono(
                                                        color: DashboardTheme
                                                            .textPale,
                                                        fontSize: 14)),

                                          // ── TEAM PRESET folder icon ──
                                          ValueListenableBuilder<
                                              List<TeamPreset>>(
                                            valueListenable: RepairRepository
                                                .instance.teamPresetsNotifier,
                                            builder: (context, presets, _) {
                                              if (presets.isEmpty)
                                                return const SizedBox(
                                                    height: 40);
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 20),
                                                child: Row(
                                                  children: [
                                                    PopupMenuButton<TeamPreset>(
                                                      tooltip:
                                                          "เลือกทีม Preset",
                                                      color: DashboardTheme
                                                          .surface,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16)),
                                                      offset:
                                                          const Offset(0, 44),
                                                      onSelected: (preset) {
                                                        setState(() {
                                                          final allSelected = preset
                                                              .memberNames
                                                              .every((n) => widget
                                                                  .draftStaffNames
                                                                  .contains(n));
                                                          if (allSelected) {
                                                            widget
                                                                .draftStaffNames
                                                                .removeWhere(
                                                                    (n) => preset
                                                                        .memberNames
                                                                        .contains(
                                                                            n));
                                                          } else {
                                                            for (final name
                                                                in preset
                                                                    .memberNames) {
                                                              if (!widget
                                                                  .draftStaffNames
                                                                  .contains(
                                                                      name))
                                                                widget
                                                                    .draftStaffNames
                                                                    .add(name);
                                                            }
                                                          }
                                                        });
                                                      },
                                                      itemBuilder: (context) =>
                                                          presets.map((preset) {
                                                        final allSelected = preset
                                                            .memberNames
                                                            .every((n) => widget
                                                                .draftStaffNames
                                                                .contains(n));
                                                        return PopupMenuItem<
                                                            TeamPreset>(
                                                          value: preset,
                                                          child: Container(
                                                            constraints:
                                                                const BoxConstraints(
                                                                    minWidth:
                                                                        220),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                        preset
                                                                            .icon,
                                                                        color: allSelected
                                                                            ? const Color(
                                                                                0xFF00E676)
                                                                            : DashboardTheme
                                                                                .primary,
                                                                        size:
                                                                            18),
                                                                    const SizedBox(
                                                                        width:
                                                                            10),
                                                                    Text(
                                                                        preset
                                                                            .name,
                                                                        style: GoogleFonts.notoSans(
                                                                            color: allSelected
                                                                                ? const Color(0xFF00E676)
                                                                                : DashboardTheme.textMain,
                                                                            fontSize: 14,
                                                                            fontWeight: FontWeight.w700)),
                                                                    const Spacer(),
                                                                    if (allSelected)
                                                                      const Icon(
                                                                          Icons
                                                                              .check_circle_rounded,
                                                                          color: Color(
                                                                              0xFF00E676),
                                                                          size:
                                                                              18),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          left:
                                                                              28),
                                                                  child: Text(
                                                                    preset
                                                                        .memberNames
                                                                        .join(
                                                                            ', '),
                                                                    style: GoogleFonts.notoSans(
                                                                        color: DashboardTheme
                                                                            .textPale,
                                                                        fontSize:
                                                                            11),
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 14,
                                                                vertical: 10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: DashboardTheme
                                                              .surfaceSecondary,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                              color: DashboardTheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .folder_rounded,
                                                                color:
                                                                    DashboardTheme
                                                                        .primary,
                                                                size: 18),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text("เลือกทีม",
                                                                style: GoogleFonts.notoSans(
                                                                    color: DashboardTheme
                                                                        .textMain,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700)),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(
                                                                "(${presets.length})",
                                                                style: GoogleFonts
                                                                    .shareTechMono(
                                                                        color: DashboardTheme
                                                                            .textPale,
                                                                        fontSize:
                                                                            10)),
                                                            const SizedBox(
                                                                width: 6),
                                                            Icon(
                                                                Icons
                                                                    .expand_more_rounded,
                                                                color:
                                                                    DashboardTheme
                                                                        .textPale,
                                                                size: 16),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 30),
                                          Container(
                                            height: 250,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: DashboardTheme.background,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: DashboardTheme.border),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: PointerInterceptor(
                                              child: ModelViewer(
                                                // No ValueKey so model-viewer stays alive across taps;
                                                // camera attrs update reactively via setState.
                                                src: 'VivornFinal8.4.glb',
                                                alt: "A 3D model of the house",
                                                autoRotate: false,
                                                cameraControls: true,
                                                cameraTarget: _cameraTarget,
                                                cameraOrbit: _cameraOrbit,
                                                backgroundColor:
                                                    Colors.transparent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          terminalText(
                                              "OPERATIONAL_CAPABILITY // RADAR",
                                              fontSize: 10,
                                              color: DashboardTheme.textPale,
                                              letterSpacing: 1),
                                          const SizedBox(height: 24),
                                          Container(
                                            height: 200,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            child: selectedTechs.isEmpty
                                                ? Icon(Icons.radar_rounded,
                                                    color: DashboardTheme
                                                        .background,
                                                    size: 100)
                                                : _buildRadarStats(
                                                    selectedTechs),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // FOOTAGE SECTION
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
                          child: Row(
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

  void _showSaveTeamDialog(BuildContext context) {
    final controller = TextEditingController();
    final memberCount = widget.draftStaffNames.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("สร้างทีมใหม่จากที่เลือก",
            style: GoogleFonts.notoSans(
                color: DashboardTheme.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("สมาชิกที่เลือกไว้ $memberCount คน:",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale, fontSize: 12)),
            const SizedBox(height: 8),
            Text(widget.draftStaffNames.join(', '),
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textSecondary, fontSize: 11),
                maxLines: 2),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              style: GoogleFonts.notoSans(color: DashboardTheme.textMain),
              decoration: InputDecoration(
                hintText: "ตั้งชื่อทีม (เช่น ทีมไฟฟ้า, กะเช้า)",
                hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale),
                filled: true,
                fillColor: DashboardTheme.background,
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
            child: Text("ยกเลิก",
                style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                RepairRepository.instance.addTeamPreset(
                  name: name,
                  memberNames: List<String>.from(widget.draftStaffNames),
                  icon: Icons.folder_rounded,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'บันทึกทีม "$name" ($memberCount คน) เรียบร้อยแล้ว',
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF00E676),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text("บันทึก",
                style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w900, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarStats(List<Map<String, dynamic>> selectedTechs) {
    Map<String, double> peakStats = {};
    final keys = selectedTechs.first['stats'].keys.cast<String>().toList();
    for (var key in keys) {
      double maxVal = 0;
      for (var tech in selectedTechs) {
        maxVal = max(maxVal, (tech['stats'][key] ?? 0.0).toDouble());
      }
      peakStats[key] = maxVal;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: RadarChartPainter(
            stats: peakStats,
            color: DashboardTheme.primary,
          ),
        );
      },
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
