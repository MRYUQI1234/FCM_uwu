import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/data/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseIdController = TextEditingController(); // House ID (New Required)
  final _nameController = TextEditingController(); // Full Name
  final _phoneController = TextEditingController(); // Phone Number
  final _emailController = TextEditingController(); // Email
  final _passwordController = TextEditingController(); // Password
  final _confirmPasswordController = TextEditingController(); // Confirm Password

  @override
  void dispose() {
    _houseIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await AuthRepository.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        houseId: _houseIdController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        final userId = result['data']['userId']; 
        if (mounted && userId != null) {
          _showPinDialog(userId);
        } else {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration Successful! Please Login.')),
              );
              Navigator.pop(context);
            }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'], style: GoogleFonts.kanit()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPinDialog(String userId) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: Text('ตั้งรหัส PIN (6 หลัก)', style: GoogleFonts.kanit(color: const Color(0xFFC5A059))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('กรุณาตั้งรหัส PIN สำหรับการใช้งานครั้งต่อไป', style: GoogleFonts.kanit(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              style: GoogleFonts.kanit(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'xxxxxx',
            hintStyle: const TextStyle(color: Colors.grey)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (pinController.text.length != 6) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN ต้องมี 6 หลัก', style: TextStyle(fontFamily: 'Kanit'))),
                );
                return;
              }
              
              // Set PIN API
              final res = await AuthRepository.instance.setPin(userId, pinController.text);
              if (res['success']) {
                if (mounted) {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Go back to Login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ลงทะเบียนและตั้ง PIN สำเร็จ!', style: TextStyle(fontFamily: 'Kanit')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                 if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['error'], style: const TextStyle(fontFamily: 'Kanit')), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('ยืนยัน', style: GoogleFonts.kanit(color: const Color(0xFFC5A059))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Desktop Web is usually wide, mimic the split layout
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                Expanded(
                  flex: 6, // More space for text
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 100.0),
                      child: _buildTitleSection(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4, // Card area
                  child: Center(
                    child: _buildRegisterForm(),
                  ),
                ),
              ],
            );
          } else {
            // Mobile / Tablet
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 48),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FACILITY',
          style: GoogleFonts.anton(
            fontSize: 96,
            height: 0.9,
            color: const Color(0xFFC5A059), // Updated Gold #c5a059
            letterSpacing: 2.0,
          ),
        ),
        Text(
          'MANAGEMENT',
          style: GoogleFonts.anton(
            fontSize: 96,
            height: 0.9,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
        Text(
          'SYSTEM',
          style: GoogleFonts.anton(
            fontSize: 96,
            height: 0.9,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450), // Slightly wider for more fields
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151515), // Very dark grey
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFC5A059), // Updated Gold #c5a059
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ลงทะเบียน',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // House ID Field (New Required)
            TextFormField(
              controller: _houseIdController,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A059),
              decoration: _inputDecoration('House ID (เช่น 123/45)'),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณากรอก House ID' : null,
            ),
            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A059),
              decoration: _inputDecoration('ชื่อ-นามสกุล'),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
            ),
            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _phoneController,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A572),
              decoration: _inputDecoration('เบอร์โทรศัพท์'),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A572),
              decoration: _inputDecoration('อีเมล'),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณากรอกอีเมล' : null,
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A572),
              decoration: _inputDecoration('รหัสผ่าน'),
              validator: (value) =>
                  value!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: GoogleFonts.kanit(color: Colors.white),
              cursorColor: const Color(0xFFC5A572),
              decoration: _inputDecoration('ยืนยันรหัสผ่าน'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณายืนยันรหัสผ่าน';
                }
                if (value != _passwordController.text) {
                  return 'รหัสผ่านไม่ตรงกัน';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Register Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B7348), // Brownish Gold
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Text(
                  'ลงทะเบียน',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login Link
            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Back to Login
                  },
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.kanit(color: Colors.grey, fontSize: 14),
                      children: [
                        const TextSpan(text: 'มีบัญชีอยู่แล้ว? '),
                        TextSpan(
                          text: 'ลงชื่อเข้าใช้',
                          style: GoogleFonts.kanit(
                            color: const Color(0xFFC5A572),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFC5A572),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.kanit(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFC5A572), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
