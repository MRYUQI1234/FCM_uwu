import 'package:flutter/material.dart';
import 'package:fcm_app/features/legal/presentation/widgets/village_map_widget.dart';
import 'package:fcm_app/features/legal/presentation/widgets/technician_card.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/personnel_dossier_overlay.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/task_assignment_overlay.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/shared/widgets/pin_verification_overlay.dart';

class OverviewView extends StatefulWidget {
  final List<Map<String, dynamic>> technicians;
  const OverviewView({super.key, required this.technicians});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  Map<String, dynamic>? _selectedTech;
  RepairRequest? _selectedTask;
  List<String> _draftStaffNames = [];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 1. THE MAIN VILLAGE MAP
              Positioned.fill(
                child: VillageMapWidget(
                  onMarkerTap: (houseShort, issue) {
                    final fullHouse = "UNIT-$houseShort";
                    final matches = RepairRepository
                        .instance.repairsNotifier.value
                        .where((r) =>
                            r.requesterHouse == fullHouse ||
                            r.requesterHouse == houseShort ||
                            r.requesterHouse == "Unit $houseShort")
                        .toList();

                    if (matches.isNotEmpty) {
                      setState(() {
                        _selectedTask = matches.first;
                        _draftStaffNames =
                            List<String>.from(_selectedTask!.assignedStaff);
                      });
                    }
                  },
                ),
              ),

              // 3. PERSONNEL DOSSIER OVERLAY
              if (_selectedTech != null)
                Positioned.fill(
                  child: PersonnelDossierOverlay(
                    technician: _selectedTech!,
                    onDismiss: () => setState(() => _selectedTech = null),
                  ),
                ),

              // 4. TASK ASSIGNMENT OVERLAY
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

                        RepairRepository.instance
                            .assignRequest(_selectedTask!.id, _draftStaffNames);
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

              // 5. TECHNICIANS CURRENTLY ON DUTY (TOP MOST FOR INTERACTIVITY)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: terminalText(
                        "พนักงานที่ปฏิบัติงานอยู่",
                        fontSize: 8.5,
                        color: Colors.white, // White font as requested
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 210,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: widget.technicians
                              .where((tech) => tech['role'] == 'TECHNICIAN')
                              .map((tech) {
                            final isActive = tech['isActive'] ?? true;
                            return TechnicianCard(
                              name: tech['name'],
                              status: isActive ? "ACTIVE" : "INACTIVE",
                              statusColor: isActive
                                  ? DashboardTheme.success
                                  : DashboardTheme.primary,
                              isActive: isActive,
                              imagePath: tech['image'],
                              roleIcon: tech['role'] == 'JURISTIC'
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.engineering_rounded,
                              role: tech['role'],
                              onTap: () {
                                if (_selectedTask != null) {
                                  if (isActive) {
                                    setState(() {
                                      if (_draftStaffNames
                                          .contains(tech['name'])) {
                                        _draftStaffNames.remove(tech['name']);
                                      } else {
                                        _draftStaffNames.add(tech['name']);
                                      }
                                    });
                                  }
                                } else {
                                  setState(() => _selectedTech = tech);
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
            ],
          ),
        );
      },
    );
  }
}
