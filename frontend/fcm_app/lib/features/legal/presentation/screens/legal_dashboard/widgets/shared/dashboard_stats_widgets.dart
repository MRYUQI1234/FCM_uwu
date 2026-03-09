import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_painters.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';

class DashboardStatsWidgets {
  static Widget buildHealthExpanded(BuildContext context, double score, int urgent, int pending) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: buildHealthCompact(score, score > 90 ? DashboardTheme.success : (score > 70 ? DashboardTheme.warning : DashboardTheme.error))),
            const SizedBox(width: 60),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _healthMiniRow("ZONE A (RESIDENTIAL)", "SAFE", DashboardTheme.success),
                  const SizedBox(height: 16),
                  _healthMiniRow("ZONE B (FACILITIES)", "WARNING", DashboardTheme.warning),
                  const SizedBox(height: 16),
                  _healthMiniRow("ZONE C (UTILITIES)", "SECURE", DashboardTheme.success),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
        buildImmersiveChart("SYSTEM STABILITY OVER TIME", [80, 85, 82, 88, 90, 87, score]),
      ],
    );
  }

  static Widget buildHealthCompact(double score, Color color) {
    return Row(
      children: [
        Text("${score.toInt()}%", style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 44, fontWeight: FontWeight.w800)),
        const SizedBox(width: 20),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 12,
              backgroundColor: DashboardTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildRatingExpanded(BuildContext context, double rating) {
    final reviews = DashboardData.reviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRatingCompact(rating),
        const SizedBox(height: 40),
        terminalText("DETAILED_METRICS // SATISFACTION_INDEX", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1.5),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ratingMiniStat("TOTAL REVIEWS", "${reviews.length}"),
            _ratingMiniStat("AVG SENTIMENT", rating.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 40),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) => buildFeedbackCard(reviews[index]),
        ),
      ],
    );
  }

  static Widget buildRatingCompact(double rating) {
    return Row(
      children: [
        Text(rating.toStringAsFixed(1), style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 44, fontWeight: FontWeight.w800)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) => Icon(
                i < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: DashboardTheme.accentAmber,
                size: 20,
              )),
            ),
            terminalText("EXCELLENT LEVEL", fontSize: 9, color: DashboardTheme.isDarkMode.value ? DashboardTheme.textPale : DashboardTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  static Widget buildEfficiencyExpanded(BuildContext context) {
    return Column(
      children: [
        buildEfficiencyCompact(),
        const SizedBox(height: 60),
        buildImmersiveChart("RESPONSE TIME BRAKDOWN (MINUTES)", [35, 28, 42, 18, 25, 30, 24]),
      ],
    );
  }

  static Widget buildEfficiencyCompact() {
    return Row(
      children: [
        Icon(Icons.bolt_rounded, color: DashboardTheme.primary, size: 36),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("24m", style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 32, fontWeight: FontWeight.w800)),
            terminalText("RESPONSE TIME", fontSize: 9, color: DashboardTheme.isDarkMode.value ? DashboardTheme.textPale : DashboardTheme.textSecondary),
          ],
        ),
      ],
    );
  }

  static Widget buildSuccessExpanded(BuildContext context, double rate) {
    return Column(
      children: [
        buildSuccessCompact(rate),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DashboardTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashboardTheme.border),
          ),
          child: Column(
            children: [
              _successRow("LEGAL ADVISORY", "100%", const Color(0xFF6366F1)),
              Divider(color: DashboardTheme.border, height: 24),
              _successRow("GENERAL MAINT.", "94.2%", DashboardTheme.accentAmber),
              Divider(color: DashboardTheme.border, height: 24),
              _successRow("CRITICAL SYSTEM", "98.9%", DashboardTheme.success),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildSuccessCompact(double rate) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120, height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate,
                strokeWidth: 10,
                backgroundColor: DashboardTheme.border,
                valueColor: AlwaysStoppedAnimation(DashboardTheme.primary),
              ),
              Text("${(rate * 100).toInt()}%", style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        terminalText("TOTAL RESOLVED: 4,218", fontSize: 10, color: DashboardTheme.textSecondary),
      ],
    );
  }

  static Widget buildFeedbackCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardTheme.border),
        boxShadow: [
          BoxShadow(
            color: DashboardTheme.isDarkMode.value ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (data['avatarColor'] as Color).withOpacity(0.1),
                child: Text(data['name'][0], style: GoogleFonts.outfit(color: data['avatarColor'] as Color, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'], style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontWeight: FontWeight.bold, fontSize: 15)),
                  terminalText(data['tag'], fontSize: 8, color: DashboardTheme.isDarkMode.value ? DashboardTheme.textPale : DashboardTheme.textSecondary),
                ],
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < (data['rating'] as double).floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: DashboardTheme.accentAmber,
                  size: 14,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['comment'],
            style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  static Widget buildImmersiveChart(String label, List<double> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        terminalText(label, fontSize: 10, color: DashboardTheme.isDarkMode.value ? DashboardTheme.textPale : DashboardTheme.textSecondary, letterSpacing: 1.5),
        const SizedBox(height: 24),
        Container(
          height: 250,
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashboardTheme.border),
          ),
          child: CustomPaint(
            painter: LineChartPainter(values: values, color: DashboardTheme.primary),
          ),
        ),
      ],
    );
  }

  static Widget _healthMiniRow(String label, String status, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        terminalText(label, fontSize: 11, color: DashboardTheme.textSecondary),
        const Spacer(),
        terminalText(status, fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ],
    );
  }

  static Widget _ratingMiniStat(String label, String val) {
    return Column(
      children: [
        terminalText(label, fontSize: 8, color: DashboardTheme.isDarkMode.value ? DashboardTheme.textPale : DashboardTheme.textSecondary),
        Text(val, style: GoogleFonts.shareTechMono(color: DashboardTheme.accentAmber, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static Widget _successRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        terminalText(label, fontSize: 10, color: DashboardTheme.textMain),
        Text(val, style: GoogleFonts.shareTechMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
