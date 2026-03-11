import 'package:flutter/material.dart';
import 'package:fcm_app/shared/models/parsed_task_model.dart';
import 'package:fcm_app/shared/models/user_info_model.dart';
import 'package:fcm_app/shared/widgets/repair_request_preview_card.dart';

class RepairConfirmationOverlay extends StatefulWidget {
  final List<ParsedTask> tasks;
  final Future<bool> Function() onConfirm;
  final VoidCallback onCancel;
  final UserInfoModel? userInfo;

  const RepairConfirmationOverlay({
    super.key,
    required this.tasks,
    required this.onConfirm,
    required this.onCancel,
    this.userInfo,
  });

  @override
  State<RepairConfirmationOverlay> createState() =>
      _RepairConfirmationOverlayState();
}

class _RepairConfirmationOverlayState extends State<RepairConfirmationOverlay> {
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);
    final success = await widget.onConfirm();
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  void _handleCancel() {
    widget.onCancel();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.transparent,
          child: RepairRequestPreviewCard(
            tasks: widget.tasks,
            userInfo: widget.userInfo,
            onConfirm: _handleConfirm,
            onCancel: _handleCancel,
            isSubmitting: _isSubmitting,
            isReadOnly: false,
          ),
        ),
      ),
    );
  }
}

Future<bool?> showRepairConfirmationOverlay({
  required BuildContext context,
  required List<ParsedTask> tasks,
  required Future<bool> Function() onConfirm,
  required VoidCallback onCancel,
  UserInfoModel? userInfo,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Confirm Repair',
    barrierColor: Colors.black.withOpacity(0.85),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: RepairConfirmationOverlay(
          tasks: tasks,
          userInfo: userInfo,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}
