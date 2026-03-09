import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_painters.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';

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
    final bool isActive = technician['isActive'] as bool? ?? true;

    Widget dialogContent = Container(
      width: 1000,
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: DashboardTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 60, spreadRadius: 10),
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
              child: Icon(Icons.security_rounded, size: 300, color: DashboardTheme.primary.withOpacity(0.02)),
            ),
            Padding(
              padding: const EdgeInsets.all(48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                border: Border.all(color: DashboardTheme.primary.withOpacity(0.3), width: 2),
                                image: DecorationImage(
                                  image: (technician['image'] as String).startsWith('assets/')
                                      ? AssetImage(technician['image'] as String) as ImageProvider
                                      : (kIsWeb 
                                          ? NetworkImage(technician['image'] as String)
                                          : FileImage(File(technician['image'] as String))),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  terminalText("PERSONNEL_DOSSIER // ${technician['id']}", fontSize: 10, color: DashboardTheme.primary.withOpacity(0.5), letterSpacing: 2),
                                  const SizedBox(height: 12),
                                  Text((technician['name'] as String).toUpperCase(), style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 42, fontWeight: FontWeight.w900)),
                                  Text(technician['role'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 24),
                                  terminalText("SPECIALIZED_SKILLS", fontSize: 9, color: DashboardTheme.textPale, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: (technician['abilities'] as List<dynamic>).map((a) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: DashboardTheme.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: DashboardTheme.primary.withOpacity(0.1)),
                                      ),
                                      child: terminalText((a as String).toUpperCase(), fontSize: 9, fontWeight: FontWeight.bold, color: DashboardTheme.primary),
                                    )).toList(),
                                  ),
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
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _dossierInfoItem("AGE", "${technician['age']}"),
                                          _dossierInfoItem("HEIGHT", technician['height'] as String),
                                          _dossierInfoItem("BIRTHPLACE", technician['birthplace'] as String),
                                          const SizedBox(height: 24),
                                          terminalText("FIELD_BIOGRAPHY", fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.w900, letterSpacing: 1),
                                          const SizedBox(height: 12),
                                          Text(technician['bio'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13, height: 1.6)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    Column(
                                      children: [
                                        terminalText("OVERALL_ABILITY_HUD", fontSize: 9, color: DashboardTheme.textPale, fontWeight: FontWeight.w900, letterSpacing: 1),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: 220,
                                          height: 220,
                                          child: CustomPaint(
                                            child: CustomPaint(
                                              painter: RadarChartPainter(
                                                stats: Map<String, double>.from(technician['stats'] as Map),
                                                color: DashboardTheme.primary,
                                                labelColor: DashboardTheme.textPale,
                                                gridColor: DashboardTheme.isDarkMode.value ? Colors.white.withOpacity(0.05) : DashboardTheme.border,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: onDismiss,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.primary.withOpacity(0.05),
                                foregroundColor: DashboardTheme.primary,
                                side: BorderSide(color: DashboardTheme.primary.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: terminalText("DISMISS DOSSIER", fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),
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
                                terminalText("AVAILABILITY_MATRIX", fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.w900, letterSpacing: 1),
                                const SizedBox(height: 4),
                                Text("WORK SCHEDULE", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 24, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            terminalText("SYNCED // 2026.02.17", fontSize: 9, color: DashboardTheme.success.withOpacity(0.5), fontWeight: FontWeight.bold),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: _buildTechScheduleCalendar(technician['name'] as String, technician['image'] as String),
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
                icon: Icon(Icons.close_rounded, color: DashboardTheme.textPale),
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
                child: isActive 
                    ? dialogContent 
                    : ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]),
                        child: dialogContent,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dossierInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          terminalText(label, fontSize: 9, color: DashboardTheme.textPale, fontWeight: FontWeight.w900, letterSpacing: 1),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTechScheduleCalendar(String name, String imagePath) {
    // 1. Generate deterministic mock schedule based on name hash
    final int seed = name.codeUnits.fold(0, (p, c) => p + c);
    final Set<int> busyDays = {};
    
    // Simulate a 5-day work week with rotating shifts
    for (int i = 1; i <= 28; i++) {
        // Simple algo: work 5 days, rest 2 days, offset by seed
        int dayInCycle = (i + seed) % 7;
        if (dayInCycle < 5) {
            busyDays.add(i);
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
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
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
                            "DUTY_SHIFT_MATRIX // ROTATION",
                            style: GoogleFonts.shareTechMono(
                              color: DashboardTheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          terminalText("STAGGERED_DUTY_PROTOCOL_v3.0 // ACTIVE_CYCLE", fontSize: 8, color: DashboardTheme.success.withOpacity(0.5)),
                        ],
                      ),
                      Icon(Icons.grid_view_rounded, color: DashboardTheme.textPale, size: 16),
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
                                child: terminalText(d, fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.bold),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: 28, 
                      itemBuilder: (context, index) {
                        final int day = index + 1;
                        final bool isBusy = busyDays.contains(day);
                        final Color statusColor = isBusy 
                            ? DashboardTheme.success.withOpacity(0.1) // Green for working
                            : DashboardTheme.error.withOpacity(0.02); // Red for unavailable
                        
                        final Color borderColor = isBusy 
                            ? DashboardTheme.success.withOpacity(0.2)
                            : DashboardTheme.error.withOpacity(0.05);

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
                              color: isBusy ? DashboardTheme.success : DashboardTheme.textPale,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Bottom Matrix Legend
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem("ON DUTY / WORKING", DashboardTheme.success),
                    _buildLegendItem("UNAVAILABLE / OFF", DashboardTheme.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
        terminalText(label, fontSize: 9, color: DashboardTheme.textSecondary, letterSpacing: 1),
      ],
    );
  }
}
