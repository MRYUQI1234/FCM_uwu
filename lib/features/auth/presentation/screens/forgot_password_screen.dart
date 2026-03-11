import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  static const Color accentGold = Color(0xFFC5A059);

  Future<void> _handleReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      final result = await AuthRepository.instance
          .requestPasswordReset(_emailController.text.trim());

      setState(() {
        _isLoading = false;
        _isSuccess = result['success'];
        _message = result['success'] ? result['message'] : result['error'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      body: Stack(
        children: [
          // Background Effects similar to Login
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
          // Back Button
          Positioned(
            top: 40,
            left: 24,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: accentGold, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                padding: const EdgeInsets.all(12),
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
                              child: const Icon(Icons.lock_reset_rounded,
                                  color: accentGold, size: 32),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Forgot Password',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enter your email address and we will send you a link to reset your password.',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildField(
                              label: 'EMAIL ADDRESS',
                              controller: _emailController,
                              icon: Icons.email_outlined,
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

  Widget _buildField(
      {required String label,
      required TextEditingController controller,
      required IconData icon}) {
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
            style: const TextStyle(color: Colors.white, fontSize: 15),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: accentGold.withOpacity(0.7), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              hintText: 'user@example.com',
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
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
        onTap: _isLoading ? null : _handleReset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accentGold, Color(0xFF8B7348)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accentGold.withOpacity(0.3),
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
                    'SEND RESET LINK',
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
