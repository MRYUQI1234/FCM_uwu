import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/data/repair_repository.dart';

class PersonnelDossierOverlay extends StatelessWidget {
  final Map<String, dynamic> technician;
  final VoidCallback onDismiss;

  const PersonnelDossierOverlay({
    super.key,
    required this.technician,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RepairRequest>>(
      valueListenable: RepairRepository.instance.repairsNotifier,
      builder: (context, repairs, child) {
        final techName = technician['name']?.toString() ?? 'Unknown';
        final techRepairs = repairs
            .where((r) => r.assignedStaff.contains(techName))
            .toList();

        Widget dialogContent = Container(
          width: 1000,
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: DashboardTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 60,
                  spreadRadius: 10),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Background Security Icon
                Positioned(
                  top: -50,
                  right: -50,
                  child: Icon(Icons.security_rounded,
                      size: 300,
                      color: DashboardTheme.primary.withOpacity(0.02)),
                ),
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- LEFT COLUMN: Personnel Details & Biography ---
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 180,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: DashboardTheme.primary
                                            .withOpacity(0.3),
                                        width: 2),
                                    image: DecorationImage(
                                      image: (technician['image'] as String)
                                              .startsWith('assets/')
                                          ? AssetImage(technician['image']
                                              as String) as ImageProvider
                                          : (kIsWeb
                                              ? NetworkImage(technician['image']
                                                  as String)
                                              : FileImage(File(
                                                  technician['image']
                                                      as String))),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      terminalText(
                                          "PERSONNEL_DOSSIER // ${technician['id']}",
                                          fontSize: 10,
                                          color: DashboardTheme.primary
                                              .withOpacity(0.5),
                                          letterSpacing: 2),
                                      const SizedBox(height: 12),
                                      Text(
                                          (technician['name'] ?? 'Unknown')
                                              .toString()
                                              .toUpperCase(),
                                          style: GoogleFonts.notoSans(
                                              color: DashboardTheme.textMain,
                                              fontSize: 42,
                                              fontWeight: FontWeight.w900)),
                                      Text(
                                          (technician['role'] ?? 'Staff')
                                              .toString(),
                                          style: GoogleFonts.notoSans(
                                              color: DashboardTheme.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    terminalText("FIELD_BIOGRAPHY",
                                        fontSize: 10,
                                        color: DashboardTheme.textPale,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1),
                                    const SizedBox(height: 12),
                                    Text((technician['bio'] ?? '').toString(),
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textSecondary,
                                            fontSize: 13,
                                            height: 1.6)),
                                    const SizedBox(height: 40),
                                    _buildUpcomingTasksList(techRepairs),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 60),

                      // --- RIGHT COLUMN: Schedule & Availability ---
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    terminalText("AVAILABILITY_MATRIX",
                                        fontSize: 10,
                                        color: DashboardTheme.textPale,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1),
                                    const SizedBox(height: 4),
                                    Text("WORK SCHEDULE",
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textMain,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                terminalText("SYNCED // 2026.03.25",
                                    fontSize: 9,
                                    color:
                                        DashboardTheme.success.withOpacity(0.5),
                                    fontWeight: FontWeight.bold),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: _buildTechScheduleCalendar(
                                techName,
                                technician['image'] as String,
                                techRepairs,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 24,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded,
                        color: DashboardTheme.textPale),
                  ),
                ),
              ],
            ),
          ),
        );

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                bottom: 270,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: ScaleTransition(
                    scale: const AlwaysStoppedAnimation(0.95),
                    child: dialogContent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechScheduleCalendar(
      String name, String imagePath, List<RepairRequest> techRepairs) {
    Set<int> upcomingDays = {};
    for (var r in techRepairs) {
      if (r.appointmentDate != null &&
          (r.status == 'ASSIGNED' ||
              r.status == 'IN PROGRESS' ||
              r.status == 'URGENT')) {
        // Match March (3) 2026 for the current dossier view
        if (r.appointmentDate!.month == 3 && r.appointmentDate!.year == 2026) {
          upcomingDays.add(r.appointmentDate!.day);
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: Stack(
        children: [
          // Ghost Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: ((imagePath.startsWith('assets/')
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : (kIsWeb
                      ? Image.network(imagePath, fit: BoxFit.cover)
                      : Image.file(File(imagePath), fit: BoxFit.cover)))),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Matrix Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "WORK_SCHEDULE // ACTIVE_TASKS",
                          style: GoogleFonts.shareTechMono(
                            color: DashboardTheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        terminalText("SYNCHRONIZED_WITH_CENTRAL_DATABASE",
                            fontSize: 8,
                            color: DashboardTheme.success.withOpacity(0.5)),
                      ],
                    ),
                    Icon(Icons.grid_view_rounded,
                        color: DashboardTheme.textPale, size: 16),
                  ],
                ),
                const SizedBox(height: 24),

                // Days Header (Condensed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["S", "M", "T", "W", "T", "F", "S"]
                      .map((d) => SizedBox(
                            width: 38,
                            child: Center(
                              child: terminalText(d,
                                  fontSize: 10,
                                  color: DashboardTheme.textPale,
                                  fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Availability Grid
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: 31,
                    itemBuilder: (context, index) {
                      final int day = index + 1;
                      final bool isUpcoming = upcomingDays.contains(day);

                      final Color statusColor = isUpcoming
                          ? DashboardTheme.success.withOpacity(0.1)
                          : DashboardTheme.surface;

                      final Color borderColor = isUpcoming
                          ? DashboardTheme.success.withOpacity(0.3)
                          : DashboardTheme.border.withOpacity(0.5);

                      return Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: terminalText(
                            "$day",
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isUpcoming
                                ? DashboardTheme.success
                                : DashboardTheme.textPale,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Matrix Legend
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("UPCOMING TASKS", DashboardTheme.success),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasksList(List<RepairRequest> techRepairs) {
    final upcoming = techRepairs
        .where((r) =>
            r.status == 'ASSIGNED' ||
            r.status == 'URGENT' ||
            r.status == 'IN PROGRESS')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        terminalText("UPCOMING_TASKS // ACTIVE",
            fontSize: 10,
            color: DashboardTheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Text("No active tasks assigned",
              style: GoogleFonts.notoSans(
                  color: DashboardTheme.textPale, fontSize: 13))
        else
          ...upcoming.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DashboardTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DashboardTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: task.status == 'URGENT'
                              ? DashboardTheme.error.withOpacity(0.1)
                              : DashboardTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          task.status == 'URGENT'
                              ? Icons.priority_high_rounded
                              : Icons.handyman_rounded,
                          size: 14,
                          color: task.status == 'URGENT'
                              ? DashboardTheme.error
                              : DashboardTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title,
                                style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textMain,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Row(
                              children: [
                                Text(task.requesterHouse ?? 'Facility',
                                    style: GoogleFonts.shareTechMono(
                                        color: DashboardTheme.textPale,
                                        fontSize: 10)),
                                const SizedBox(width: 8),
                                if (task.appointmentDate != null)
                                  terminalText(
                                      DateFormat('dd MMM yy')
                                          .format(task.appointmentDate!),
                                      fontSize: 8,
                                      color: DashboardTheme.primary
                                          .withOpacity(0.7)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      terminalText(task.status.replaceAll('_', ' '),
                          fontSize: 8,
                          color: task.status == 'URGENT'
                              ? DashboardTheme.error
                              : DashboardTheme.success,
                          fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        terminalText(label,
            fontSize: 9, color: DashboardTheme.textSecondary, letterSpacing: 1),
      ],
    );
  }
}
