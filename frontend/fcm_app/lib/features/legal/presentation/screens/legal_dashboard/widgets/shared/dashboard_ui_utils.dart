import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

// Light Mode Theme Constants
Color get retroAmber => DashboardTheme.primary; 
Color get retroAmberDim => DashboardTheme.primaryDim;
Color get retroBg => DashboardTheme.background;

Widget terminalText(String text, {double fontSize = 12, Color? color, FontWeight fontWeight = FontWeight.w900, double letterSpacing = 0.5, TextAlign? textAlign, List<Shadow>? shadows}) {
  return Text(
    text.toUpperCase(),
    textAlign: textAlign,
    style: GoogleFonts.shareTechMono(
      color: color ?? DashboardTheme.textMain,
      fontSize: fontSize,
      fontWeight: fontWeight, 
      letterSpacing: letterSpacing,
      shadows: shadows,
    ),
  );
}

Widget terminalHeader(String text, {double fontSize = 28, Color? color}) {
  return Text(
    text,
    style: GoogleFonts.vt323(
      color: color ?? retroAmber,
      fontSize: fontSize,
      letterSpacing: 1.0,
    ),
  );
}

class MetricCard extends StatelessWidget {
  final String label;
  final Widget child;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.child,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _HoverMetricCard(
        label: label,
        icon: icon,
        color: color,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _HoverMetricCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  const _HoverMetricCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.child,
    this.onTap,
  });

  @override
  State<_HoverMetricCard> createState() => _HoverMetricCardState();
}

class _HoverMetricCardState extends State<_HoverMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 140,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isHovered ? DashboardTheme.primaryDim : DashboardTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? DashboardTheme.primary.withOpacity(0.3) : DashboardTheme.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.03),
                blurRadius: _isHovered ? 20 : 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.notoSans(
                      color: _isHovered ? DashboardTheme.primary : DashboardTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    widget.icon, 
                    color: _isHovered ? DashboardTheme.primary : DashboardTheme.textPale, 
                    size: 18
                  ),
                ],
              ),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

void showDashboardOverlay({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required Widget content,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: DashboardTheme.textMain.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.transparent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 100, 60, 60),
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: DashboardTheme.cardDecoration(
                  borderRadius: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 28),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  title,
                                  style: GoogleFonts.outfit(
                                    color: DashboardTheme.textMain,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            terminalText(subtitle, fontSize: 11, color: DashboardTheme.textSecondary, letterSpacing: 2),
                          ],
                        ),
                        Material(
                          color: DashboardTheme.surfaceSecondary,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: DashboardTheme.textMain, size: 28),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(opacity: anim1, child: child);
    },
  );
}
