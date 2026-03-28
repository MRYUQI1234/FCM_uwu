import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable 6-digit PIN pad with dot indicators and a 0–9 number grid.
class PinPadWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final ValueChanged<String> onComplete;
  final VoidCallback? onChanged;
  final bool showError;
  final String? errorMessage;

  const PinPadWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.onComplete,
    this.onChanged,
    this.showError = false,
    this.errorMessage,
  });

  @override
  State<PinPadWidget> createState() => _PinPadWidgetState();
}

class _PinPadWidgetState extends State<PinPadWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  static const int _pinLength = 6;
  static const Color _gold = Color(0xFFFFD700);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkBg = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void didUpdateWidget(covariant PinPadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showError && !oldWidget.showError) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
        setState(() => _pin = '');
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
    });
    if (widget.onChanged != null) widget.onChanged!();
    if (_pin.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 150), () {
        widget.onComplete(_pin);
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
    if (widget.onChanged != null) widget.onChanged!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkBg,
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.title,
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: GoogleFonts.kanit(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),

                // Dot indicators with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value * (_shakeController.status == AnimationStatus.forward ? 1 : -1), 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (i) {
                      final filled = i < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: filled ? 18 : 16,
                        height: filled ? 18 : 16,
                        decoration: BoxDecoration(
                          color: filled
                              ? (widget.showError ? Colors.red : _gold)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.showError
                                ? Colors.red
                                : (filled ? _gold : Colors.white24),
                            width: 2,
                          ),
                          boxShadow: filled && !widget.showError
                              ? [
                                  BoxShadow(
                                    color: _gold.withOpacity(0.4),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // Error message
                if (widget.showError && widget.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.errorMessage!,
                    style: GoogleFonts.kanit(
                      color: Colors.red,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 48),

                // Number pad (1-9, then empty, 0, backspace)
                ..._buildNumberPad(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNumberPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 72, height: 72);
            }
            if (key == 'back') {
              return _padButton(
                child: const Icon(Icons.backspace_outlined,
                    color: Colors.white70, size: 24),
                onTap: _onBackspace,
              );
            }
            return _padButton(
              child: Text(
                key,
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _onDigitPressed(key),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _padButton({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: _gold.withOpacity(0.15),
        highlightColor: _gold.withOpacity(0.08),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _darkSurface,
            border: Border.all(color: Colors.white10),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
