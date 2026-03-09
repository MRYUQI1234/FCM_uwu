import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

// ═══════════════════════════════════════════════════════════
// Shared widgets for the Resident Dashboard (Dark + Gold)
// ═══════════════════════════════════════════════════════════

class DarkCard extends StatelessWidget {
  final Widget child;
  const DarkCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: DashboardTheme.cardDecoration(),
      child: child,
    );
  }
}

class AnnouncementItem extends StatelessWidget {
  final String date, title, desc;
  final Color color;
  final bool showBorder;

  const AnnouncementItem({
    super.key,
    required this.date,
    required this.color,
    required this.title,
    required this.desc,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: showBorder
          ? BoxDecoration(border: Border(bottom: BorderSide(color: DashboardTheme.border)))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              date,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.outfit(fontSize: 13, color: DashboardTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final String? label;

  const IconBtn({
    super.key,
    required this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DashboardTheme.textMain),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: GoogleFonts.outfit(fontSize: 12, color: DashboardTheme.textMain),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'รอ':
      case 'รอดำเนินการ':
        color = DashboardTheme.warning;
        label = 'Pending';
        break;
      case 'ดำเนินการ':
        color = DashboardTheme.primaryBlue;
        label = 'In Progress';
        break;
      case 'เสร็จสิ้น':
        color = DashboardTheme.success;
        label = 'Completed';
        break;
      case 'ปฏิเสธ':
        color = DashboardTheme.error;
        label = 'Rejected';
        break;
      default:
        color = DashboardTheme.textPale;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DashboardTheme.textMain,
      ),
    );
  }
}

class DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const DarkTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontSize: 14, color: DashboardTheme.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: DashboardTheme.textPale),
        filled: true,
        fillColor: DashboardTheme.surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.primary, width: 2),
        ),
      ),
    );
  }
}
