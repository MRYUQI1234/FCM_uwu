import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/shared/widgets/pin_pad_widget.dart';

class PinSetupScreen extends StatefulWidget {
  final String targetRoute;

  const PinSetupScreen({super.key, required this.targetRoute});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _step = 1; // 1 = enter, 2 = confirm
  String _firstPin = '';
  bool _showError = false;
  String? _errorMessage;
  bool _loading = false;
  int _key = 0;

  static const Color _gold = Color(0xFFFFD700);

  void _onFirstPinComplete(String pin) {
    setState(() {
      _firstPin = pin;
      _step = 2;
      _showError = false;
      _errorMessage = null;
      _key++;
    });
  }

  Future<void> _onConfirmPinComplete(String pin) async {
    if (pin != _firstPin) {
      setState(() {
        _showError = true;
        _errorMessage = 'รหัส PIN ไม่ตรงกัน กรุณาลองใหม่';
        _step = 1;
        _firstPin = '';
      });
      return;
    }

    setState(() => _loading = true);

    final result = await AuthRepository.instance.setPin(pin);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, widget.targetRoute);
    } else {
      setState(() {
        _loading = false;
        _showError = true;
        _errorMessage = result['error'] ?? 'ไม่สามารถตั้งค่า PIN ได้';
        _step = 1;
        _firstPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Decorative background
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withOpacity(0.1),
                      border: Border.all(
                        color: _gold.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: _gold,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepDot(1),
                      Container(
                        width: 40,
                        height: 2,
                        color: _step >= 2
                            ? _gold
                            : Colors.white12,
                      ),
                      _stepDot(2),
                    ],
                  ),
                  const SizedBox(height: 8),

                  PinPadWidget(
                    key: ValueKey(_key),
                    title: _step == 1
                        ? 'ตั้งรหัส PIN ใหม่'
                        : 'ยืนยันรหัส PIN อีกครั้ง',
                    subtitle: _step == 1
                        ? 'กรุณากำหนดรหัส PIN 6 หลัก เพื่อใช้ยืนยันตัวตน'
                        : 'กรุณากรอกรหัส PIN อีกครั้ง เพื่อยืนยัน',
                    onComplete: _step == 1
                        ? _onFirstPinComplete
                        : _onConfirmPinComplete,
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

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CircularProgressIndicator(color: _gold),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int step) {
    final bool active = _step >= step;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? _gold : Colors.transparent,
        border: Border.all(
          color: active ? _gold : Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: GoogleFonts.kanit(
            color: active ? Colors.black : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
