import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class TechnicianCard extends StatefulWidget {
  final String name;
  final String status;
  final String? imagePath;
  final Color statusColor;
  final bool isActive;
  final bool isSelected; // SRS: Green highlight when assigned
  final int shiftOffset;
  final IconData? roleIcon;
  final String? role;
  final VoidCallback? onTap;

  const TechnicianCard({
    super.key,
    required this.name,
    required this.status,
    this.imagePath,
    required this.statusColor,
    this.isActive = false,
    this.isSelected = false,
    this.shiftOffset = 0,
    this.roleIcon,
    this.role,
    this.onTap,
  });

  @override
  State<TechnicianCard> createState() => _TechnicianCardState();
}

class _TechnicianCardState extends State<TechnicianCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color currentColor = widget.statusColor;
    final String currentStatus = widget.isSelected ? "SELECTED" : (widget.isActive ? "ACTIVE" : "INACTIVE");
    // SRS: Green highlight color when selected
    final Color selectedGreen = const Color(0xFF00E676);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.08 : (_isHovered ? 1.05 : (widget.isActive ? 1.0 : 0.90)),
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? selectedGreen.withOpacity(0.08)
                  : (_isHovered ? DashboardTheme.surfaceSecondary : DashboardTheme.surface),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isSelected
                    ? selectedGreen
                    : (widget.isActive 
                        ? currentColor.withOpacity(_isHovered ? 0.6 : 0.3) 
                        : currentColor.withOpacity(_isHovered ? 0.3 : 0.12)),
                width: widget.isSelected ? 2.0 : 0.8,
              ),
              boxShadow: widget.isSelected ? [
                BoxShadow(
                  color: selectedGreen.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: selectedGreen.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ] : ((widget.isActive || _isHovered) ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: _isHovered ? 15 : 10,
                  offset: const Offset(0, 4),
                )
              ] : []),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.isSelected ? [
                        selectedGreen.withOpacity(0.9),
                        selectedGreen.withOpacity(0.6),
                      ] : [
                        widget.isActive ? currentColor.withOpacity(0.9) : currentColor.withOpacity(0.15),
                        widget.isActive ? currentColor.withOpacity(0.6) : currentColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isSelected) ...[
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        currentStatus,
                        style: GoogleFonts.notoSans(
                          color: widget.isSelected ? Colors.white : (widget.isActive ? Colors.white : currentColor.withOpacity(0.6)),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Portrait
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: DashboardTheme.background,
                          border: Border.all(color: DashboardTheme.border),
                        ),
                        child: ClipRect(
                          child: widget.imagePath != null
                              ? Image.asset(
                                  widget.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                  color: widget.isActive ? null : Colors.grey,
                                  colorBlendMode: widget.isActive ? null : BlendMode.saturation,
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                    ),
                    if (!widget.isActive)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          color: Colors.black.withOpacity(0.6), // Darken inactive
                        ),
                      ),
                    // Role Icon Badge
                    if (widget.roleIcon != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: currentColor.withOpacity(0.3)),
                          ),
                          child: Icon(widget.roleIcon, color: currentColor, size: 14),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CustomPaint(
                          painter: _HUDBracketPainter(color: (widget.isActive || _isHovered) ? currentColor.withOpacity(0.6) : DashboardTheme.textPale.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Footer (Name & Role)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        widget.name.toUpperCase(),
                        style: GoogleFonts.notoSans(
                          color: (widget.isActive || _isHovered) ? DashboardTheme.textMain : DashboardTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      if (widget.role != null)
                        Text(
                          widget.role!.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            color: currentColor.withOpacity(widget.isActive ? 0.7 : 0.3),
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: DashboardTheme.surfaceSecondary,
      child: Icon(Icons.person, color: DashboardTheme.textPale.withOpacity(0.2), size: 32),
    );
  }
}

class _HUDBracketPainter extends CustomPainter {
  final Color color;
  _HUDBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const cornerLength = 8.0;

    // Top Left
    canvas.drawPath(Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, 0)
      ..lineTo(cornerLength, 0), paint);

    // Top Right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, cornerLength), paint);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height)
      ..lineTo(cornerLength, size.height), paint);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final double opacity;
  _GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DashboardTheme.textPale.withOpacity(opacity)
      ..strokeWidth = 0.5;

    const gap = 6.0;
    for (double i = 0; i <= size.width; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += gap) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
