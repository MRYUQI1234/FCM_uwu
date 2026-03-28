import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/data/auth_repository.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  static const Color accentGold = Color(0xFFC5A059);

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result = await AuthRepository.instance
          .resetPassword(widget.token, _passwordController.text);

      setState(() {
        _isLoading = false;
        _isSuccess = result['success'];
        _message = result['success'] ? result['message'] : result['error'];
      });

      if (_isSuccess) {
        // Delay and then navigate back to login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: Stack(
        children: [
          // Background Effects
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF141A2F), Color(0xFF0D0D0E)],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accentGold.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.password_rounded,
                                  color: accentGold, size: 32),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Reset Password',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please enter your new password.',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildPasswordField(
                              label: 'NEW PASSWORD',
                              controller: _passwordController,
                              isConfirm: false,
                            ),
                            const SizedBox(height: 24),
                            _buildPasswordField(
                              label: 'CONFIRM PASSWORD',
                              controller: _confirmPasswordController,
                              isConfirm: true,
                            ),
                            const SizedBox(height: 32),
                            if (_message != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isSuccess
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _isSuccess
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _message!,
                                  style: GoogleFonts.kanit(
                                    color: _isSuccess
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            _buildPrimaryButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isConfirm,
  }) {
    final bool isVisible = isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: accentGold.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !isVisible,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            validator: (v) {
               if (v == null || v.isEmpty) return 'Required';
               if (!isConfirm) {
                  if (v.length < 6) return 'Password must be at least 8 characters';
                  if (!RegExp('^(?=.*[a-z])(?=.*[A-Z]).{8}').hasMatch(v)) {
                    return 'Password must contain at least one uppercase letter and one lowercase letter';
                  }
               } else {
                  if (v != _passwordController.text) return 'Passwords do not match';
               }
               return null;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline, color: accentGold.withOpacity(0.7), size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirm) {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    } else {
                      _isPasswordVisible = !_isPasswordVisible;
                    }
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isLoading || _isSuccess ? null : _handleReset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSuccess 
                ? [Colors.green.shade600, Colors.green.shade800] 
                : [accentGold, const Color(0xFF8B7348)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isSuccess ? Colors.green.withOpacity(0.3) : accentGold.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2),
                  )
                : Text(
                    _isSuccess ? 'SUCCESS' : 'RESET PASSWORD',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
