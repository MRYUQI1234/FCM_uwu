import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/shared/models/parsed_task_model.dart';
import 'package:fcm_app/shared/models/user_info_model.dart';

/// Modular repair request preview card.
/// Usable from AI Chat, manual forms, QR scan, etc.
class RepairRequestPreviewCard extends StatelessWidget {
  final List<ParsedTask> tasks;
  final UserInfoModel? userInfo;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isSubmitting;
  final bool isReadOnly;
  final VoidCallback? onTap;
  final String? actionState;

  const RepairRequestPreviewCard({
    super.key,
    required this.tasks,
    this.userInfo,
    this.onConfirm,
    this.onCancel,
    this.isSubmitting = false,
    this.isReadOnly = false,
    this.onTap,
    this.actionState,
  });

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bathroom':
        return Icons.bathtub_rounded;
      case 'electrical':
        return Icons.bolt_rounded;
      case 'plumbing':
        return Icons.water_drop_rounded;
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'bedroom':
        return Icons.bed_rounded;
      case 'living room':
        return Icons.weekend_rounded;
      case 'garden':
        return Icons.grass_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final t = TranslationService.instance;
    final gold = DashboardTheme.primary;

    // --- SLEEK IN-CHAT CARD (isReadOnly = true) ---
    if (isReadOnly) {
      final firstTaskName = tasks.first.objectType;
      final extraCount = tasks.length > 1 ? ' +${tasks.length - 1}' : '';
      final titleText = '$firstTaskName$extraCount';

      // Determine state style if provided
      Color stateColor = DashboardTheme.textPale;
      String stateText = '';
      if (actionState == 'pending') {
        stateColor = Colors.orange;
        stateText = 'Pending';
      } else if (actionState == 'confirmed') {
        stateColor = Colors.green;
        stateText = 'Confirmed';
      } else if (actionState == 'cancelled') {
        stateColor = Colors.red;
        stateText = 'Cancelled';
      }

      final sleekCard = Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gold.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.build_circle_rounded, color: gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('request_preview_title'),
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titleText,
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (stateText.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stateColor.withOpacity(0.3)),
                ),
                child: Text(
                  stateText,
                  style: GoogleFonts.outfit(
                    color: stateColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: gold.withOpacity(0.5)),
          ],
        ),
      );

      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          child:
              MouseRegion(cursor: SystemMouseCursors.click, child: sleekCard),
        );
      }
      return sleekCard;
    }

    // --- DETAILED OVERLAY CARD (isReadOnly = false) ---
    Widget content = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_rounded, color: gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.t('request_preview_title'),
                    style: GoogleFonts.outfit(
                      color: gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length} ${t.t('request_preview_tasks')}',
                    style: GoogleFonts.outfit(
                        color: gold, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // User Info Section
          if (userInfo != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: DashboardTheme.border.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resident Details', // Fallback, could be translated
                      style: GoogleFonts.outfit(
                        color: DashboardTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.home_work_rounded, color: gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'House: ${userInfo!.houseNumber}',
                          style: GoogleFonts.outfit(
                            color: DashboardTheme.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_rounded, color: gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          userInfo!.name,
                          style: GoogleFonts.outfit(
                            color: DashboardTheme.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (userInfo!.email != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email_rounded, color: gold, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            userInfo!.email!,
                            style: GoogleFonts.outfit(
                              color: DashboardTheme.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (userInfo!.phone != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, color: gold, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            userInfo!.phone!,
                            style: GoogleFonts.outfit(
                              color: DashboardTheme.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Task rows
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: tasks.asMap().entries.map((entry) {
                  final task = entry.value;
                  return _TaskRow(
                      task: task, icon: _iconForType(task.objectType));
                }).toList(),
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: DashboardTheme.border.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: DashboardTheme.textPale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      t.t('request_preview_cancel'),
                      style: GoogleFonts.outfit(
                        color: DashboardTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Confirm
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                t.t('request_preview_confirm'),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return content;
  }
}

class _TaskRow extends StatelessWidget {
  final ParsedTask task;
  final IconData icon;

  const _TaskRow({required this.task, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = TranslationService.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DashboardTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DashboardTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + urgency badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.objectName ?? task.objectType,
                        style: GoogleFonts.outfit(
                          color: DashboardTheme.textMain,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          t.t('request_preview_emergency'),
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // Description
                Text(
                  task.description,
                  style: GoogleFonts.outfit(
                    color: DashboardTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.preferDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: DashboardTheme.textPale, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${task.preferDate}${task.preferTime != null ? ' ${task.preferTime}' : ''}',
                        style: GoogleFonts.outfit(
                          color: DashboardTheme.textPale,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
