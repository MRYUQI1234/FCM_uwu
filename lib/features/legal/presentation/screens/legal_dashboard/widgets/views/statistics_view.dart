import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_stats_widgets.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/core/data/repair_repository.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  double get _calculatedAvgRating => DashboardData.calculatedAvgRating;

  void _showDetailOverlay({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    showDashboardOverlay(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      content: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<RepairRequest>>(
      valueListenable: RepairRepository.instance.repairsNotifier,
      builder: (context, repairs, child) {
        final urgentCount =
            repairs.where((t) => t.status == "URGENT" || t.isEmergency).length;
        final pendingCount = repairs
            .where((t) =>
                t.status == "AWAITING APPROVAL" ||
                t.status == "PENDING" ||
                t.status == "ASSIGNED")
            .length;
        final workingCount =
            repairs.where((t) => t.status == "IN PROGRESS").length;
        final doneCount = repairs.where((t) => t.status == "COMPLETED").length;

        const totalHistorical = 4281;
        const resolvedHistorical = 4127;
        final globalVolumeTotal = totalHistorical + repairs.length;
        final resolvedTotal = resolvedHistorical + doneCount;
        final successRate = (resolvedTotal / globalVolumeTotal);

        final healthScore =
            (100 - (urgentCount * 5 + pendingCount * 2 + workingCount * 1))
                .clamp(0, 100)
                .toDouble();
        final Color healthColor = healthScore > 90
            ? DashboardTheme.success
            : (healthScore > 70
                ? DashboardTheme.warning
                : DashboardTheme.error);

        return Container(
          color: DashboardTheme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 100, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        terminalText("ข้อมูลเชิงลึกการปฏิบัติงาน // สถิติ",
                            fontSize: 10,
                            color: DashboardTheme.isDarkMode.value
                                ? DashboardTheme.primary.withOpacity(0.5)
                                : DashboardTheme.primary,
                            letterSpacing: 1.5),
                        const SizedBox(height: 12),
                        Text(
                          "สถิติข้อมูลโครงการ",
                          style: GoogleFonts.outfit(
                              color: DashboardTheme.textMain,
                              fontSize: 36,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Text(
                      "Feb 19, 2026",
                      style: GoogleFonts.shareTechMono(
                          color: DashboardTheme.textPale, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // --- STAGGERED DIVERSE LAYOUT ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (60%)
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildExpandableCard(
                            id: "health",
                            title: "สถานะโครงการ",
                            subtitle: "ความสมบูรณ์ของโครงสร้างและระบบ",
                            icon: Icons.shield_rounded,
                            color: healthColor,
                            compactChild:
                                DashboardStatsWidgets.buildHealthCompact(
                                    healthScore, healthColor),
                            expandedChild:
                                DashboardStatsWidgets.buildHealthExpanded(
                                    context,
                                    healthScore,
                                    urgentCount,
                                    pendingCount),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildExpandableCard(
                                  id: "rating",
                                  title: "ความพึงพอใจ",
                                  subtitle: "ค่าเฉลี่ยจากลูกบ้าน",
                                  icon: Icons.star_rounded,
                                  color: DashboardTheme.accentAmber,
                                  compactChild:
                                      DashboardStatsWidgets.buildRatingCompact(
                                          _calculatedAvgRating),
                                  expandedChild:
                                      DashboardStatsWidgets.buildRatingExpanded(
                                          context, _calculatedAvgRating),
                                  isClickable: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildExpandableCard(
                                  id: "efficiency",
                                  title: "ประสิทธิภาพทีม",
                                  subtitle: "เวลาตอบสนองโดยเฉลี่ย",
                                  icon: Icons.timer_rounded,
                                  color: DashboardTheme.primary,
                                  compactChild: DashboardStatsWidgets
                                      .buildEfficiencyCompact(),
                                  expandedChild: DashboardStatsWidgets
                                      .buildEfficiencyExpanded(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column (40%)
                    Expanded(
                      flex: 4,
                      child: _buildExpandableCard(
                        id: "success",
                        title: "อัตราความสำเร็จ",
                        subtitle: "การแก้ไขปัญหาทั้งหมด",
                        icon: Icons.track_changes_rounded,
                        color: DashboardTheme.primary,
                        compactChild: DashboardStatsWidgets.buildSuccessCompact(
                            successRate),
                        expandedChild:
                            DashboardStatsWidgets.buildSuccessExpanded(
                                context, successRate),
                        height: 464, // Tall card for right side
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bottom Section: Mini metrics
                Row(
                  children: [
                    _buildMiniMetric(
                        "งานค้าง",
                        "${urgentCount + pendingCount + workingCount}",
                        Icons.assignment_late_rounded,
                        DashboardTheme.surface),
                    const SizedBox(width: 16),
                    _buildMiniMetric("แก้ไขแล้ว (ประวัติ)", "$resolvedTotal",
                        Icons.check_circle_rounded, DashboardTheme.surface),
                    const SizedBox(width: 16),
                    _buildMiniMetric("ระบบ", "เสถียร", Icons.sync_rounded,
                        DashboardTheme.primaryDim),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget compactChild,
    required Widget expandedChild,
    double? height,
    bool isClickable = true,
  }) {
    return _HoverExpandableCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      compactChild: compactChild,
      onTap: isClickable
          ? () => _showDetailOverlay(
                title: title,
                subtitle: subtitle,
                icon: icon,
                color: color,
                content: expandedChild,
              )
          : null,
      height: height,
    );
  }

  // --- HEALTH VARIANTS (CLEANED) ---
  Widget _buildMiniMetric(String label, String value, IconData icon, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: DashboardTheme.cardDecoration(color: bg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DashboardTheme.textSecondary, size: 18),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.shareTechMono(
                    color: DashboardTheme.textMain,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            terminalText(label,
                fontSize: 9, color: DashboardTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _HoverExpandableCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget compactChild;
  final VoidCallback? onTap;
  final double? height;

  const _HoverExpandableCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.compactChild,
    this.onTap,
    this.height,
  });

  @override
  State<_HoverExpandableCard> createState() => _HoverExpandableCardState();
}

class _HoverExpandableCardState extends State<_HoverExpandableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = DashboardTheme.isDarkMode.value;
    final bool canClick = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = canClick),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: canClick ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height ?? 220,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -4.0 : 0.0),
          decoration: DashboardTheme.cardDecoration(
            color: _isHovered
                ? (isDark
                    ? widget.color.withOpacity(0.08)
                    : widget.color.withOpacity(0.05))
                : null,
            borderColor: _isHovered ? widget.color.withOpacity(0.5) : null,
          ).copyWith(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark
                    ? (_isHovered ? 0.4 : 0.2)
                    : (_isHovered ? 0.1 : 0.03)),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 15 : 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background Accent
              Positioned(
                top: -40,
                right: -40,
                child: Icon(widget.icon,
                    color: isDark
                        ? widget.color.withOpacity(_isHovered ? 0.05 : 0.02)
                        : Colors.transparent,
                    size: 200),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            terminalText(widget.title,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: widget.color,
                                letterSpacing: 1.2),
                            const SizedBox(height: 4),
                            terminalText(widget.subtitle,
                                fontSize: 9,
                                color: isDark
                                    ? DashboardTheme.textPale
                                    : DashboardTheme.textSecondary,
                                fontWeight: FontWeight.bold),
                          ],
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isHovered
                                ? widget.color.withOpacity(0.2)
                                : widget.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(widget.icon, color: widget.color, size: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    widget.compactChild,
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        terminalText("ดูวิเคราะห์ทั้งหมด",
                            fontSize: 8,
                            color: _isHovered
                                ? widget.color
                                : DashboardTheme.textPale),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.only(left: _isHovered ? 8 : 0),
                          child: Icon(Icons.arrow_outward_rounded,
                              color: _isHovered
                                  ? widget.color
                                  : DashboardTheme.textPale,
                              size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
