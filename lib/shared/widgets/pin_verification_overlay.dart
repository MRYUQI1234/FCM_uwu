import 'package:flutter/material.dart';

import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/shared/widgets/pin_pad_widget.dart';

/// Shows a PIN verification overlay as a full-screen dialog.
/// Returns `true` if PIN is correct, `false` or `null` if cancelled.
Future<bool?> showPinVerificationOverlay(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (_) => const _PinVerificationDialog(),
  );
}

class _PinVerificationDialog extends StatefulWidget {
  const _PinVerificationDialog();

  @override
  State<_PinVerificationDialog> createState() =>
      _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<_PinVerificationDialog> {
  bool _showError = false;
  String? _errorMessage;
  bool _loading = false;

  Future<void> _verify(String pin) async {
    setState(() {
      _loading = true;
      _showError = false;
      _errorMessage = null;
    });

    final result = await AuthRepository.instance.verifyPin(pin);

    if (!mounted) return;

    if (result) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _showError = true;
        _errorMessage = 'รหัส PIN ไม่ถูกต้อง';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 400,
              constraints: const BoxConstraints(maxHeight: 580),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white38),
                      ),
                    ),
                    Flexible(
                      child: PinPadWidget(
                        title: 'ยืนยันตัวตน',
                        subtitle: 'กรุณากรอกรหัส PIN 6 หลัก',
                        onComplete: _verify,
                        onChanged: () {
                          if (_showError) {
                            setState(() {
                              _showError = false;
                              _errorMessage = null;
                            });
                          }
                        },
                        showError: _showError,
                        errorMessage: _errorMessage,
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
