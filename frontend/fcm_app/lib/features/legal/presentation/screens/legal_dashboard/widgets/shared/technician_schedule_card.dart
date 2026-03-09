import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class TechnicianScheduleCard extends StatelessWidget {
  final Map<String, dynamic> technician;
  final VoidCallback onRemove;

  const TechnicianScheduleCard({
    super.key,
    required this.technician,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String name = technician['name'] as String;
    final String role = technician['role'] as String;
    final String imagePath = technician['image'] as String;

    // 1. Generate deterministic mock schedule based on name hash (same as in dossier)
    final int seed = name.codeUnits.fold(0, (p, c) => p + c);
    final Set<int> busyDays = {};
    
    // Simulate a 5-day work week with rotating shifts
    for (int i = 1; i <= 28; i++) {
        int dayInCycle = (i + seed) % 7;
        if (dayInCycle < 5) {
            busyDays.add(i);
        }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ghost Background Image
            Positioned.fill(
              child: Opacity(
                opacity: 0.02,
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
                  // Card Header: Name, Role, Trash Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                            Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: DashboardTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SCHEDULE: $name ($role)",
                                style: GoogleFonts.shareTechMono(
                                  color: DashboardTheme.textMain,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              terminalText("CURRENT_MONTH // FEBRUARY 2026", fontSize: 8, color: DashboardTheme.textPale),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: Icon(Icons.delete_outline_rounded, color: DashboardTheme.error, size: 20),
                        tooltip: "Remove Technician",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Month Title
                  Text(
                    "FEBRUARY 2026",
                    style: GoogleFonts.shareTechMono(
                      color: DashboardTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Days Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ["S", "M", "T", "W", "T", "F", "S"]
                        .map((d) => SizedBox(
                              width: 32,
                              child: Center(
                                child: terminalText(d, fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Availability Grid
                  GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 28, 
                    itemBuilder: (context, index) {
                      final int day = index + 1;
                      final bool isBusy = busyDays.contains(day);
                      final Color statusColor = isBusy 
                          ? DashboardTheme.success.withOpacity(0.08)
                          : DashboardTheme.surfaceSecondary;
                      
                      final Color borderColor = isBusy 
                          ? DashboardTheme.success.withOpacity(0.2)
                          : DashboardTheme.border;

                      return Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
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
                
                  // Bottom Matrix Legend
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("WORKING", DashboardTheme.success),
                      const SizedBox(width: 24),
                      _buildLegendItem("VACANT", DashboardTheme.textPale),
                      const SizedBox(width: 24),
                      _buildLegendItem("DUE / SELECTED", DashboardTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              if (color != DashboardTheme.textPale) BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        terminalText(label, fontSize: 8, color: DashboardTheme.textSecondary, letterSpacing: 0.5),
      ],
    );
  }
}
