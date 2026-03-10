import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class ResidentHistoryView extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onMenuTap;

  const ResidentHistoryView({
    super.key,
    required this.isDark,
    this.onMenuTap,
  });

  @override
  State<ResidentHistoryView> createState() => _ResidentHistoryViewState();
}

class _ResidentHistoryViewState extends State<ResidentHistoryView> {
  String _activeFilter = 'all';
  RepairRequest? _expandedTicket;
  final _ts = TranslationService.instance;

  @override
  void initState() {
    super.initState();
    RepairRepository.instance.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: DashboardTheme.isDarkMode,
        builder: (context, isDark, _) {
          return ValueListenableBuilder<List<RepairRequest>>(
              valueListenable: RepairRepository.instance.repairsNotifier,
              builder: (context, repairs, _) {
                // Calculate real-time counts for the header tabs
                final totalCount = repairs.length;
                final awaitingCount = repairs
                    .where((r) => r.status == 'AWAITING APPROVAL')
                    .length;
                final pendingCount =
                    repairs.where((r) => r.status == 'PENDING').length;
                final progressCount =
                    repairs.where((r) => r.status == 'IN PROGRESS').length;
                final completedCount =
                    repairs.where((r) => r.status == 'COMPLETED').length;
                final rejectedCount =
                    repairs.where((r) => r.status == 'REJECTED').length;

                final filtered = repairs.where((r) {
                  if (_activeFilter == 'all') return true;
                  return r.status.toLowerCase() ==
                          _activeFilter.toLowerCase() ||
                      r.status.replaceAll(' ', '').toLowerCase() ==
                          _activeFilter.toLowerCase();
                }).toList();

                return Stack(
                  children: [
                    Container(
                      color: DashboardTheme.background,
                      padding: const EdgeInsets.fromLTRB(40, 72, 40, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (widget.onMenuTap != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: GestureDetector(
                                        onTap: widget.onMenuTap,
                                        child: Icon(Icons.menu_rounded,
                                            color: DashboardTheme.primary,
                                            size: 28),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _ts.t('history_title'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: DashboardTheme.textMain,
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _ts.t('history_subtitle'),
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: DashboardTheme.textPale,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Admin-Style Standardized Filter Bar - Now Left Aligned
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: DashboardTheme.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: DashboardTheme.border),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModernTab(
                                          'ALL',
                                          "$totalCount",
                                          _activeFilter == 'all',
                                          () => setState(
                                              () => _activeFilter = 'all')),
                                      _buildModernTab(
                                          'AWAITING APPROVAL',
                                          "$awaitingCount",
                                          _activeFilter == 'AWAITING APPROVAL',
                                          () => setState(() => _activeFilter =
                                              'AWAITING APPROVAL')),
                                      _buildModernTab(
                                          'PENDING',
                                          "$pendingCount",
                                          _activeFilter == 'PENDING',
                                          () => setState(
                                              () => _activeFilter = 'PENDING')),
                                      _buildModernTab(
                                          'IN PROGRESS',
                                          "$progressCount",
                                          _activeFilter == 'IN PROGRESS',
                                          () => setState(() =>
                                              _activeFilter = 'IN PROGRESS')),
                                      _buildModernTab(
                                          'COMPLETED',
                                          "$completedCount",
                                          _activeFilter == 'COMPLETED',
                                          () => setState(() =>
                                              _activeFilter = 'COMPLETED')),
                                      _buildModernTab(
                                          'REJECTED',
                                          "$rejectedCount",
                                          _activeFilter == 'REJECTED',
                                          () => setState(() =>
                                              _activeFilter = 'REJECTED')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildEmptyState()
                                : ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 120),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      String displayStatus =
                                          filtered[index].status.toUpperCase();

                                      return _PremiumServiceCard(
                                        item: filtered[index],
                                        displayStatus: displayStatus,
                                        onTap: () => setState(() =>
                                            _expandedTicket = filtered[index]),
                                        onAction: () => _showAssessmentDialog(
                                            filtered[index]),
                                        actionWidget:
                                            _buildActionCell(filtered[index]),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_expandedTicket != null)
                      _buildDetailOverlay(_expandedTicket!),
                  ],
                );
              });
        });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: DashboardTheme.textPale.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            _ts.t('empty_records'),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: DashboardTheme.textPale.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTab(
      String label, String count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? DashboardTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive
                  ? DashboardTheme.primary.withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color:
                    isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isActive ? DashboardTheme.primary : DashboardTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color:
                        isActive ? Colors.transparent : DashboardTheme.border),
              ),
              child: Text(
                count,
                style: GoogleFonts.shareTechMono(
                  color: isActive ? Colors.black : DashboardTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssessmentDialog(RepairRequest item) {
    int localRating = 0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.08 * (1 - value))
                    ..scale(0.85 + (0.15 * value)),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: _TactileFeedbackCard(
                item: item,
                commentCtrl: commentCtrl,
                rating: localRating,
                onRatingChanged: (r) => setDialogState(() => localRating = r),
                onSubmit: () {
                  final updated = RepairRequest(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    date: item.date,
                    status: item.status,
                    statusColor: item.statusColor,
                    imagePaths: item.imagePaths,
                    completionDate: item.completionDate,
                    rating: localRating,
                    assessmentComment: commentCtrl.text,
                    technicianName: item.technicianName,
                  );
                  RepairRepository.instance.updateRequest(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Feedback submitted successfully!',
                          style: GoogleFonts.outfit()),
                      backgroundColor: DashboardTheme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHistoryCancelConfirmation(RepairRequest item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: DashboardTheme.error.withOpacity(0.3)),
        ),
        title: Text(_ts.t('cancel_confirm_title'),
            style: GoogleFonts.outfit(
                color: DashboardTheme.textMain, fontWeight: FontWeight.bold)),
        content: Text(_ts.t('cancel_confirm_body'),
            style: GoogleFonts.outfit(color: DashboardTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_ts.t('go_back'),
                style: GoogleFonts.outfit(
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              RepairRepository.instance.deleteRequest(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(_ts.t('request_cancelled'),
                        style: GoogleFonts.outfit()),
                    backgroundColor: DashboardTheme.error),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardTheme.error.withOpacity(0.1),
              foregroundColor: DashboardTheme.error,
              elevation: 0,
              side: BorderSide(color: DashboardTheme.error.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_ts.t('confirm_cancel'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCell(RepairRequest item) {
    final s = item.status.toLowerCase();

    // Case 1: Pending (Allow Cancellation)
    if (s == 'pending' || s == 'รอดำเนินการ' || s == 'รอ') {
      return TextButton.icon(
        onPressed: () => _showHistoryCancelConfirmation(item),
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(_ts.t('cancel')),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent.withOpacity(0.7),
          textStyle:
              GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Case 2: Completed (Allow Assessment)
    final isDone = (s == 'completed' || s == 'เสร็จสิ้น');
    if (!isDone) return const SizedBox();

    // SRS Rule: Can assess within 7 days
    bool isWithin7Days = true;
    if (item.completionDate != null) {
      final diff = DateTime.now().difference(item.completionDate!);
      isWithin7Days = diff.inDays <= 7;
    }

    if (item.rating != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: DashboardTheme.primary, size: 16),
          const SizedBox(width: 4),
          Text(
            '${item.rating}.0',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DashboardTheme.primary,
            ),
          ),
        ],
      );
    }

    if (!isWithin7Days) return const SizedBox();

    return TextButton.icon(
      onPressed: () => _showAssessmentDialog(item),
      icon: const Icon(Icons.rate_review_rounded, size: 16),
      label: Text(_ts.t('assess')),
      style: TextButton.styleFrom(
        foregroundColor: DashboardTheme.primary,
        textStyle:
            GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDetailOverlay(RepairRequest t) {
    final displayStatus = t.status.toUpperCase();
    final dateStr = t.appointmentDate != null
        ? DateFormat('MMM dd, yyyy').format(t.appointmentDate!)
        : 'N/A';
    final timeStr = t.appointmentTime != null
        ? t.appointmentTime!.format(context)
        : (t.appointmentDate != null
            ? DateFormat('HH:mm').format(t.appointmentDate!)
            : 'N/A');

    // Parse object name from title (format: "Room - ObjectName")
    final titleParts = t.title.split(' - ');
    final objectCategory = titleParts.length > 1 ? titleParts[0].trim() : '';
    final objectName = titleParts.length > 1 ? titleParts[1].trim() : t.title;

    return Positioned.fill(
      child: Container(
        color: (DashboardTheme.isDarkMode.value
                ? Colors.black
                : const Color(0xFFFDFBF7))
            .withOpacity(0.92),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _TactileSlab(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Close Button Row ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OBJECT',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DashboardTheme.primary.withOpacity(0.6),
                                letterSpacing: 3,
                              ),
                            ),
                            _buildCloseBtn(
                                () => setState(() => _expandedTicket = null)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── Object Name (Hero) ──
                        Text(
                          objectName,
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: DashboardTheme.textMain,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),

                        if (objectCategory.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: DashboardTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      DashboardTheme.primary.withOpacity(0.2)),
                            ),
                            child: Text(
                              objectCategory.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: DashboardTheme.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Status Badge ──
                        Row(
                          children: [
                            _LuxuryStatusLabel(
                                status: displayStatus, color: t.statusColor),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Details Section ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DashboardTheme.textMain.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: DashboardTheme.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ISSUE DETAILS',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 11,
                                  color: DashboardTheme.textPale,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.description.isNotEmpty
                                    ? t.description
                                    : 'N/A',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: DashboardTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Chronology ──
                        Divider(color: DashboardTheme.border, height: 1),
                        const SizedBox(height: 20),
                        Text(_ts.t('chronology'),
                            style: GoogleFonts.shareTechMono(
                                color: DashboardTheme.textPale,
                                fontSize: 13,
                                letterSpacing: 2)),
                        const SizedBox(height: 16),
                        _ReviewRow(label: _ts.t('logged_on'), value: t.date),
                        _ReviewRow(
                            label: _ts.t('schedule'),
                            value: '$dateStr at $timeStr'),
                        if (t.completionDate != null)
                          _ReviewRow(
                              label: _ts.t('completed_label'),
                              value: DateFormat('MMM dd, yyyy')
                                  .format(t.completionDate!),
                              isGreen: true),

                        // ── Technician ──
                        if (t.technicianName != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: DashboardTheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      DashboardTheme.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.engineering_rounded,
                                    color: DashboardTheme.primary),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_ts.t('assigned_technician'),
                                        style: GoogleFonts.shareTechMono(
                                            fontSize: 11,
                                            color: DashboardTheme.primary)),
                                    Text(t.technicianName!,
                                        style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: DashboardTheme.textMain)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── Photos ──
                        if (t.imagePaths.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Text(_ts.t('photo_documentation'),
                              style: GoogleFonts.shareTechMono(
                                  color: DashboardTheme.textPale,
                                  fontSize: 13,
                                  letterSpacing: 2)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: t.imagePaths.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, idx) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(t.imagePaths[idx]),
                                    width: 300, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseBtn(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DashboardTheme.textMain.withOpacity(0.05),
        ),
        child:
            Icon(Icons.close_rounded, size: 20, color: DashboardTheme.textPale),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Tactile Feedback Card — Dark Gold Theme
// ─────────────────────────────────────────────────
class _TactileFeedbackCard extends StatelessWidget {
  final RepairRequest item;
  final TextEditingController commentCtrl;
  final int rating;
  final Function(int) onRatingChanged;
  final VoidCallback onSubmit;

  const _TactileFeedbackCard({
    required this.item,
    required this.commentCtrl,
    required this.rating,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: DashboardTheme.primary.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 50,
            offset: const Offset(0, 25),
          ),
          BoxShadow(
            color: DashboardTheme.primary.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Subtle grain texture
            Positioned.fill(
              child: CustomPaint(painter: _DarkGrainPainter()),
            ),

            // Gold accent line at top
            Positioned(
              top: 0,
              left: 40,
              right: 40,
              child: Container(
                  height: 2, color: DashboardTheme.primary.withOpacity(0.4)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SERVICE COMPLETION',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: DashboardTheme.primary.withOpacity(0.5),
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'FEEDBACK CARD',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: DashboardTheme.textMain,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: DashboardTheme.primary.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.apartment_rounded,
                            color: DashboardTheme.primary, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Separator ──
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          DashboardTheme.primary.withOpacity(0.2),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Info Section ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _infoLine('OBJECT', item.title),
                        const SizedBox(height: 10),
                        _infoLine('SERVICE', item.title),
                        const SizedBox(height: 10),
                        _infoLine('DATE', item.date),
                        if (item.technicianName != null) ...[
                          const SizedBox(height: 10),
                          _infoLine('TECHNICIAN', item.technicianName!),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Quality Assessment ──
                  Text(
                    'QUALITY ASSESSMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DashboardTheme.primary.withOpacity(0.5),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stars ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isSelected = index < rating;
                      return GestureDetector(
                        onTap: () => onRatingChanged(index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? DashboardTheme.primary.withOpacity(0.12)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? DashboardTheme.primary.withOpacity(0.3)
                                  : DashboardTheme.textPale.withOpacity(0.1),
                            ),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: isSelected
                                ? DashboardTheme.primary
                                : DashboardTheme.textPale.withOpacity(0.3),
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 36),

                  // ── Comment Area ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESIDENT COMMENTS',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentCtrl,
                        maxLines: 2,
                        style: GoogleFonts.caveat(
                          fontSize: 22,
                          color: DashboardTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your feedback here...',
                          hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: DashboardTheme.textPale.withOpacity(0.4)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: DashboardTheme.border),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: DashboardTheme.primary.withOpacity(0.5)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // ── Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.outfit(
                            color: Colors.white30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: rating == 0 ? null : onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardTheme.primary,
                          foregroundColor: DashboardTheme.surface,
                          disabledBackgroundColor:
                              DashboardTheme.textPale.withOpacity(0.05),
                          disabledForegroundColor:
                              DashboardTheme.textPale.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: Text(
                          'SUBMIT RECORD',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Gold Seal (5 stars only) ──
            if (rating == 5)
              Positioned(
                top: 24,
                right: 24,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(angle: -0.15, child: child),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE6BE75),
                          Color(0xFFC5A03A),
                          Color(0xFFE6BE75)
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DashboardTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF3D2E0D), size: 24),
                          const SizedBox(height: 2),
                          Text(
                            'EXCELLENT',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3D2E0D),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white30,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
  final RepairRequest item;
  final String displayStatus;
  final VoidCallback onAction;
  final VoidCallback onTap;
  final Widget actionWidget;

  const _PremiumServiceCard({
    required this.item,
    required this.displayStatus,
    required this.onAction,
    required this.actionWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          color: DashboardTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: DashboardTheme.border
                  .withOpacity(DashboardTheme.isDarkMode.value ? 0.03 : 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(DashboardTheme.isDarkMode.value ? 0.4 : 0.05),
              blurRadius: 40,
              offset: const Offset(10, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Minimal Color Indicator
                Container(width: 4, color: item.statusColor),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 32),
                    child: Row(
                      children: [
                        // Date
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.date,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: DashboardTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          height: 40,
                          color: DashboardTheme.border,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                        ),

                        // Subject
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: DashboardTheme.textMain,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (item.technicianName != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'ASSIGNED: ${item.technicianName!.toUpperCase()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        DashboardTheme.primary.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Status & Action
                        Row(
                          children: [
                            _LuxuryStatusLabel(
                                status: displayStatus, color: item.statusColor),
                            const SizedBox(width: 40),
                            SizedBox(
                              width: 120,
                              child: actionWidget,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LuxuryStatusLabel extends StatelessWidget {
  final String status;
  final Color color;

  const _LuxuryStatusLabel({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color.withOpacity(0.8),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _DarkGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.008)
      ..style = PaintingStyle.fill;

    const spacing = 5.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        if ((i + j) % (spacing * 3) == 0) {
          canvas.drawCircle(Offset(i, j), 0.4, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
// OVERLAY HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════

class _TactileSlab extends StatelessWidget {
  final Widget child;
  const _TactileSlab({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: DashboardTheme.border
                .withOpacity(DashboardTheme.isDarkMode.value ? 0.04 : 0.4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(DashboardTheme.isDarkMode.value ? 0.5 : 0.05),
              blurRadius: 40,
              offset: const Offset(0, 20)),
          BoxShadow(
              color: DashboardTheme.textMain.withOpacity(0.05),
              blurRadius: 0,
              spreadRadius: -1,
              offset: const Offset(-1, -1)),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(top: 15, left: 15, child: _Screw()),
          const Positioned(top: 15, right: 15, child: _Screw()),
          const Positioned(bottom: 15, left: 15, child: _Screw()),
          const Positioned(bottom: 15, right: 15, child: _Screw()),
          child,
        ],
      ),
    );
  }
}

class _Screw extends StatelessWidget {
  const _Screw();
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardTheme.textPale.withOpacity(0.1)));
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;
  final bool isGreen;
  final bool isBold;
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isGreen = false,
    this.isRed = false,
    this.isBold = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.outfit(
                  color: DashboardTheme.textPale, fontSize: 16)),
          Text(value.isEmpty ? 'N/A' : value,
              style: GoogleFonts.outfit(
                  color: isRed
                      ? Colors.redAccent
                      : (isGreen
                          ? Colors.greenAccent
                          : DashboardTheme.textSecondary),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 17))
        ]));
  }
}

class _OverlayBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutline;
  const _OverlayBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.isOutline = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 60,
            decoration: BoxDecoration(
                color: isOutline ? Colors.transparent : color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3))),
            alignment: Alignment.center,
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color:
                        isOutline ? DashboardTheme.textPale : Colors.black))));
  }
}

class _PhotoPreview extends StatelessWidget {
  final String path;
  const _PhotoPreview({required this.path});
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white10));
    } else {
      return Image.file(File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white10));
    }
  }
}
