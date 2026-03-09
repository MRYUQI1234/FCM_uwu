import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class VillageMapWidget extends StatefulWidget {
  final Function(String house, String issue)? onMarkerTap;
  const VillageMapWidget({super.key, this.onMarkerTap});

  @override
  State<VillageMapWidget> createState() => _VillageMapWidgetState();
}

class _VillageMapWidgetState extends State<VillageMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: DashboardTheme.isDarkMode,
        builder: (context, isDark, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
              // Real Village Map Asset
              Positioned.fill(
                child: Image.asset(
                  'assets/village_map.jpg',
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.0), // Darken only in Dark Mode
                  colorBlendMode: BlendMode.darken,
                ),
              ),

              // Tech Grid Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.1,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated Scan Line
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ScanLinePainter(
                          progress: _scanController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // HUD Corner Brackets
              Positioned.fill(
                child: CustomPaint(
                  painter: HudCornerPainter(),
                ),
              ),


              // Dynamic Issue Markers from DashboardData
              ...DashboardData.tasks.where((task) {
                // Show markers ONLY for RESIDENTIAL UNITS (UNIT-*) that are PENDING or URGENT
                final String house = task['house']?.toString() ?? "";
                return house.startsWith('UNIT-') && 
                       DashboardData.houseMarkerPositions.containsKey(house) && 
                       (task['status'] == "PENDING" || task['status'] == "URGENT");
              }).map((task) {
                final Offset pos = DashboardData.houseMarkerPositions[task['house']]!;
                return Positioned(
                  top: constraints.maxHeight * pos.dy,
                  left: constraints.maxWidth * pos.dx,
                  child: _buildMarkerWidget(
                    icon: (task['icon'] is IconData) ? task['icon'] as IconData : Icons.warning_rounded,
                    color: task['status'] == 'URGENT' ? DashboardTheme.error : (task['status'] == 'WORKING' ? DashboardTheme.success : DashboardTheme.primary),
                    house: (task['house'] as String).replaceFirst('UNIT-', ''),
                    issue: (task['title'] as String).length > 30 
                      ? (task['title'] as String).substring(0, 30) + "..."
                      : task['title'] as String,
                    requester: task['requester'] ?? "Admin",
                    category: task['category'] ?? "Maintenance",
                    status: task['status'] ?? "PENDING",
                  ),
                );
              }),

              // Bottom status bar overlay
              Positioned(
                bottom: 14,
                left: 28,
                right: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            "RESIDENT TASKS",
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _hudBadge(
                              "Pending", 
                              DashboardData.tasks.where((t) => t['status'] == 'PENDING' && t['house'].toString().startsWith('UNIT-')).length.toString(), 
                              DashboardTheme.primary
                            ),
                            const SizedBox(width: 16),
                            _hudBadge(
                              "Urgent", 
                              DashboardData.tasks.where((t) => t['status'] == 'URGENT' && t['house'].toString().startsWith('UNIT-')).length.toString(), 
                              DashboardTheme.error
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      "VIVORN Village  ·  SECTOR OVERVIEW",
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  ),
);
  }

  Widget _hudBadge(String label, String count, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$label ",
            style: GoogleFonts.notoSans(
              color: DashboardTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            count,
            style: GoogleFonts.notoSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget({
    required IconData icon,
    required Color color,
    required String house,
    required String issue,
    required String requester,
    required String category,
    required String status,
  }) {
    return GestureDetector(
      onTap: () => widget.onMarkerTap?.call(house, issue),
      child: RepaintBoundary(
        child: _PulsingMarker(
          icon: icon,
          color: color,
          house: house,
          issue: issue,
          requester: requester,
          category: category,
          status: status,
        ),
      ),
    );
  }
}

// Pulsing marker with animation
class _PulsingMarker extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String house;
  final String issue;
  final String requester;
  final String category;
  final String status;

  const _PulsingMarker({
    required this.icon,
    required this.color,
    required this.house,
    required this.issue,
    required this.requester,
    required this.category,
    required this.status,
  });

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final isUrgent = widget.color == DashboardTheme.error;
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: isUrgent ? 800 : 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Outer pulse ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(0.3 * pulseValue),
                      width: 2 + (pulseValue * 2),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DashboardTheme.isDarkMode.value ? DashboardTheme.surface : Colors.white, // Dark marker in Dark Mode
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color, 
                        width: 1.8, 
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.2 + pulseValue * 0.2),
                          blurRadius: 8 + (pulseValue * 4), 
                          spreadRadius: 1 + (pulseValue * 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon, 
                      color: widget.color, 
                      size: widget.color == DashboardTheme.error ? 20 : 16, 
                    ),
                  ),
                ),
                // Connector line
                Container(
                  width: 1.5,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [widget.color, widget.color.withOpacity(0.0)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
              // Glass label - High Contrast
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DashboardTheme.isDarkMode.value 
                    ? Colors.black.withOpacity(0.8) 
                    : Colors.white.withOpacity(0.9),
                border: Border.all(
                  color: widget.color.withOpacity(0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.status == 'URGENT' 
                      ? '🚨 URGENT: ${widget.house} | ${widget.requester.split(' ')[0]}' 
                      : (widget.status == 'WORKING' ? '🛠️ ON-GOING: ${widget.house} | ${widget.requester.split(' ')[0]}' : 'H: ${widget.house} | ${widget.requester.split(' ')[0]}'),
                    style: GoogleFonts.shareTechMono(
                      color: widget.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                  widget.issue.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: DashboardTheme.textMain,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Grid Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardTheme.primary.withOpacity(0.12)
      ..strokeWidth = 0.5;

    const spacing = 50.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Scan Line Painter
class ScanLinePainter extends CustomPainter {
  final double progress;
  ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          DashboardTheme.primary.withOpacity(0.06),
          DashboardTheme.primary.withOpacity(0.12),
          DashboardTheme.primary.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, y - 40, size.width, 80), paint);

    // Thin bright line
    final linePaint = Paint()
      ..color = DashboardTheme.primary.withOpacity(0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) => true;
}

// HUD Corner Bracket Painter
class HudCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardTheme.primary.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const len = 30.0;
    const margin = 12.0;

    // Top-left
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + len, margin),
      paint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin, margin + len),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - len, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + len),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + len, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - len),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - len, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
