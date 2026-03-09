import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/widgets/village_map_widget.dart';
import 'package:fcm_app/features/legal/presentation/widgets/technician_card.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/personnel_dossier_overlay.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/task_assignment_overlay.dart';

class OverviewView extends StatefulWidget {
  const OverviewView({super.key});

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  Map<String, dynamic>? _selectedTech;
  Map<String, dynamic>? _selectedTask;
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
                    final task = DashboardData.tasks.firstWhere(
                      (t) => t['house'] == fullHouse || t['house'] == houseShort,
                      orElse: () => {},
                    );
                    
                    if (task.isNotEmpty) {
                      setState(() {
                        _selectedTask = task;
                        _draftStaffNames = List<String>.from(task['staffNames'] ?? []); 
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
                        "TECHNICIANS CURRENTLY ON DUTY", 
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
                          children: DashboardData.technicians.map((tech) {
                            return TechnicianCard(
                              name: tech['name'],
                              status: tech['isActive'] ? "ACTIVE" : "INACTIVE",
                              statusColor: tech['isActive'] ? DashboardTheme.success : DashboardTheme.primary,
                              isActive: tech['isActive'],
                              imagePath: tech['image'],
                              roleIcon: tech['icon'],
                              role: tech['role'],
                              onTap: () {
                                if (_selectedTask != null) {
                                  if (tech['isActive']) {
                                    setState(() {
                                      if (_draftStaffNames.contains(tech['name'])) {
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
