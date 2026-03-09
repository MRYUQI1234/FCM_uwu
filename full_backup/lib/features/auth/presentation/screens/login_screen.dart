import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/data/auth_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Form State
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _houseIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoginMode = true; // Added back for in-place toggle
  bool _isPanelOpen = false;
  bool _isPasswordVisible = false;
  bool _isButtonHovered = false;
  bool _isAccessButtonHovered = false; // Added for top-right button
  bool _isSwitchHovered = false; // Added for bottom toggle links
  bool _isCloseHovered = false; // Added for top-right close button
  static const Color accentGold = Color(0xFFC5A059);
  static const Color deepGold = Color(0xFF8B7348);
  int _currentFeatureIndex = 0;

  int _currentSeasonIndex = 0;
  int _previousSeasonIndex = 0;
  late AnimationController _weatherController;
  late AnimationController _seasonTransitionController;

  bool _isTransitioning = false;

  final List<Map<String, dynamic>> _seasons = [
    {
      'name': 'SUMMER',
      'label': 'HOT & VIBRANT',
      'colors': [const Color(0xFF4D3624), const Color(0xFF23180F)],
      'accent': const Color(0xFFFFB74D),
      'exposure': 1.3, 
      'weather': 'haze',
    },
    {
      'name': 'RAINY',
      'label': 'SOFT & HUMID',
      'colors': [const Color(0xFF2E3F47), const Color(0xFF141C1F)],
      'accent': const Color(0xFF4DB6AC),
      'exposure': 0.6, 
      'weather': 'rain',
    },
    {
      'name': 'WINTER',
      'label': 'CRISP & QUIET',
      'colors': [const Color(0xFF3B4D61), const Color(0xFF1A1F2B)],
      'accent': const Color(0xFF81D4FA),
      'exposure': 0.9,
      'weather': 'snow',
    },
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.home_work_rounded,
      'title': 'Smart Building',
      'desc': 'Monitor every room in one tap.'
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Live Dashboard',
      'desc': 'See repairs & status in real-time.'
    },
    {
      'icon': Icons.build_circle_rounded,
      'title': 'Quick Repairs',
      'desc': 'Report issues, track fixes instantly.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _seasonTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _cycleFeatures();
    _cycleSeasons();
  }

  void _cycleSeasons() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 7));
      if (mounted) {
        setState(() {
          _previousSeasonIndex = _currentSeasonIndex;
          _currentSeasonIndex = (_currentSeasonIndex + 1) % _seasons.length;
          _isTransitioning = true;
        });
        _seasonTransitionController.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              _isTransitioning = false;
              _previousSeasonIndex = _currentSeasonIndex;
            });
          }
        });
      }
    }
  }

  void _cycleFeatures() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _currentFeatureIndex = (_currentFeatureIndex + 1) % _features.length;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _idCardController.dispose();
    _houseIdController.dispose();
    _phoneController.dispose();
    _weatherController.dispose();
    _seasonTransitionController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final formKey = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLoginMode) {
        final result = await AuthRepository.instance.login(email, password);
        setState(() => _isLoading = false);
        if (result['success']) {
          if (mounted) {
            final role = result['data']['role'];
            if (role == 'legal') {
              Navigator.pushReplacementNamed(context, '/legal');
            } else if (role == 'technician') {
              Navigator.pushReplacementNamed(context, '/technician');
            } else {
              Navigator.pushReplacementNamed(context, '/3d_model');
            }
          }
        } else {
          if (mounted) _showError(result['error']);
        }
      } else {
        // Quick Success for Sign Up
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('สมัครสมาชิกสำเร็จ!',
                  style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
          // Clear register fields
          _idCardController.clear();
          _houseIdController.clear();
          _nameController.clear();
          _phoneController.clear();
          _confirmPasswordController.clear();
          setState(() => _isLoginMode = true);
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.kanit()),
        backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 950;

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: DashboardTheme.background,
          body: Stack(
            children: [
              _buildBackground(screenWidth, isMobile),
              // Interaction Shield (Placed above the background/model but below UI)
              if (!isMobile)
                Positioned.fill(
                  child: PointerInterceptor(
                    intercepting: true,
                    child: GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              if (!isMobile && !_isPanelOpen) _buildGeometricAccents(),
              if (!isMobile && !_isPanelOpen) _buildHeroTagline(),
              if (!isMobile) _buildFeatureTicker(),
              if (!isMobile) _buildSeasonStatus(), // Added to bottom-right
              Positioned(
                top: 40,
                left: isMobile ? 24 : 60,
                child: _buildBranding(),
              ),
              if (!isMobile && !_isPanelOpen)
                Positioned(
                  right: 60,
                  top: 40,
                  child: Row(
                    children: [
                      _buildThemeToggle(),
                      const SizedBox(width: 20),
                      _buildAccessButton(),
                    ],
                  ),
                ),
              // Theme toggle for mobile
              if (isMobile && !_isPanelOpen)
                Positioned(
                  top: 35,
                  right: 20,
                  child: _buildThemeToggle(),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
                top: 0,
                bottom: 0,
                right: _isPanelOpen ? 0 : -500,
                width: isMobile ? screenWidth : 500,
                child: _buildPanel(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, _) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: DashboardTheme.toggleTheme,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  key: ValueKey(isDark),
                  color: isDark ? accentGold : DashboardTheme.primaryBlue,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(double screenWidth, bool isMobile) {
    return AnimatedBuilder(
      animation: _seasonTransitionController,
      builder: (context, child) {
        final t = _seasonTransitionController.value;
        final currentSeason = _seasons[_currentSeasonIndex];
        final previousSeason = _seasons[_previousSeasonIndex];

        final List<Color> colors = [
          Color.lerp(
              previousSeason['colors'][0], currentSeason['colors'][0], t)!,
          Color.lerp(
              previousSeason['colors'][1], currentSeason['colors'][1], t)!,
        ];

        final Color seasonAccent = Color.lerp(
              previousSeason['accent'] as Color,
              currentSeason['accent'] as Color,
              t,
            )!;

        return Stack(
          children: [
            // Base gradient background
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: DashboardTheme.isDarkMode.value 
                              ? colors 
                              : [DashboardTheme.background, DashboardTheme.surfaceSecondaryLight])))),
            // 3D Model
            Positioned.fill(
              child: IgnorePointer(
                child: ModelViewer(
                  key: const ValueKey('fcm_house_vivorn'),
                  backgroundColor: Colors.transparent,
                  src: 'assets/models/house.glb',
                  alt: 'Vivorn Smart House',
                  autoRotate: true,
                  autoPlay: true,
                  cameraControls: false,
                  disableZoom: true,
                  exposure: lerpDouble(
                    previousSeason['exposure'] as double,
                    currentSeason['exposure'] as double,
                    t,
                  )!,
                  shadowIntensity: 0.4,
                  shadowSoftness: 1.0,
                  rotationPerSecond: '8deg',
                  cameraTarget: 'auto 1.2m auto',
                  cameraOrbit: '225deg 80deg 105%',
                ),
              ),
            ),
            _buildWeatherLayer(
                previousSeason['weather'], previousSeason['accent'], 1.0 - t),
            _buildWeatherLayer(
                currentSeason['weather'], currentSeason['accent'], t),
          ],
        );
      },
    );
  }

  Widget _buildWeatherLayer(String type, Color color, double opacity) {
    return Positioned.fill(
        child: Opacity(
            opacity: _isTransitioning
                ? opacity.clamp(0, 1)
                : (opacity > 0.5 ? 1.0 : 0.0),
            child: _buildWeatherEffect(type, color)));
  }

  Widget _buildWeatherEffect(String type, Color color) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _weatherController,
          builder: (context, child) => CustomPaint(
              painter: WeatherPainter(
                  type: type,
                  color: color,
                  progress: _weatherController.value)),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border.all(color: accentGold.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.shield_rounded, color: accentGold, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FCM PLATFORM',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: DashboardTheme.textMain,
                    letterSpacing: 2)),
            Text('ENTERPRISE QUALITY MANAGEMENT',
                style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: accentGold.withOpacity(0.9),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureTicker() {
    final feature = _features[_currentFeatureIndex];
    return Positioned(
      bottom: 60,
      left: 60,
      child: SizedBox(
        width: 320,
        height: 70,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Row(
            key: ValueKey(_currentFeatureIndex),
            children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: accentGold.withOpacity(0.05), // Reduced from 0.1
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accentGold
                              .withOpacity(0.15))), // Reduced from 0.3
                  child: Icon(feature['icon'],
                      color: accentGold.withOpacity(0.8), size: 26)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(feature['title'],
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: DashboardTheme.textMain)),
                        const SizedBox(height: 4),
                        Text(feature['desc'],
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: DashboardTheme.textSecondary))
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccessButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isAccessButtonHovered = true),
      onExit: (_) => setState(() => _isAccessButtonHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isPanelOpen = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          transform: Matrix4.identity()
            ..scale(_isAccessButtonHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isAccessButtonHovered
                  ? [accentGold, deepGold]
                  : [deepGold, accentGold],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color:
                    accentGold.withOpacity(_isAccessButtonHovered ? 0.6 : 0.3),
                blurRadius: _isAccessButtonHovered ? 25 : 20,
                offset: Offset(0, _isAccessButtonHovered ? 10 : 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login_rounded, color: Colors.black, size: 18),
              const SizedBox(width: 10),
              Text('Sign In',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border(
              left: BorderSide(color: Colors.white.withAlpha(20), width: 1))),
      child: ClipRect(
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Reduced for stability
          child: Container(
            color: Colors.black.withOpacity(0.4), // Darker overlay fallback
            child: Stack(
              children: [
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: SingleChildScrollView(
                      key: ValueKey(_isLoginMode),
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _isLoginMode
                            ? _buildLoginForm()
                            : _buildRegisterForm(),
                      ),
                    ),
                  ),
                ),
                // Re-positioned button to top of stack and removed !isMobile restriction
                Positioned(
                  top: 32,
                  right: 32,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isCloseHovered = true),
                    onExit: (_) => setState(() => _isCloseHovered = false),
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      onPressed: () => setState(() {
                        _isPanelOpen = false;
                        _isCloseHovered = false;
                      }),
                      icon: Icon(
                        Icons.close_rounded,
                        color: _isCloseHovered ? accentGold : DashboardTheme.textPale,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: DashboardTheme.textMain.withOpacity(_isCloseHovered ? 0.15 : 0.05),
                      ),
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign In',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textMain)),
          const SizedBox(height: 8),
          Text('Welcome back. Please enter your credentials.',
              style: GoogleFonts.outfit(fontSize: 14, color: DashboardTheme.textSecondary)),
          const SizedBox(height: 48),
          _buildField('Email', _emailController, Icons.email_outlined),
          const SizedBox(height: 24),
          _buildField('Password', _passwordController, Icons.lock_outline,
              isPassword: true),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?',
                      style: TextStyle(color: accentGold, fontSize: 13)))),
          const SizedBox(height: 40),
          _buildPrimaryButton('Sign In'),
          const SizedBox(height: 32),
          _buildSwitchMode('Don\'t have an account?', 'Sign Up',
              () => setState(() => _isLoginMode = false)),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign Up',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textMain)),
          const SizedBox(height: 8),
          Text('Create an account to start managing assets.',
              style: GoogleFonts.outfit(fontSize: 14, color: DashboardTheme.textSecondary)),
          const SizedBox(height: 36),

          // SRS: 13-digit National ID Card
          _buildValidatedField(
            label: 'เลขบัตรประชาชน (13 หลัก)',
            controller: _idCardController,
            icon: Icons.credit_card_rounded,
            maxLength: 13,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'กรุณากรอกหมายเลขบัตรประชาชน';
              if (v.length != 13) return 'กรุณากรอกให้ครบ 13 หลัก';
              if (!RegExp(r'^[0-9]{13}').hasMatch(v)) return 'ต้องเป็นตัวเลขเท่านั้น';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // SRS: House ID
          _buildValidatedField(
            label: 'House ID (เช่น 123/45)',
            controller: _houseIdController,
            icon: Icons.home_rounded,
            validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก House ID' : null,
          ),
          const SizedBox(height: 20),

          _buildField('Full Name', _nameController, Icons.person_outline),
          const SizedBox(height: 20),

          // SRS: Phone (10 digits)
          _buildValidatedField(
            label: 'เบอร์โทรศัพท์',
            controller: _phoneController,
            icon: Icons.phone_rounded,
            maxLength: 10,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
              if (!RegExp(r'^[0-9]{10}').hasMatch(v)) return 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก';
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildField('Email', _emailController, Icons.email_outlined),
          const SizedBox(height: 20),

          _buildField('Password', _passwordController, Icons.lock_outline,
              isPassword: true),
          const SizedBox(height: 20),

          // SRS: Confirm Password
          _buildValidatedField(
            label: 'ยืนยันรหัสผ่าน',
            controller: _confirmPasswordController,
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
              if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
              return null;
            },
          ),
          const SizedBox(height: 36),

          _buildPrimaryButton('Sign Up'),
          const SizedBox(height: 32),
          _buildSwitchMode('Already have an account?', 'Sign In',
              () => setState(() => _isLoginMode = true)),
        ],
      ),
    );
  }

  Widget _buildSwitchMode(String text, String action, VoidCallback onTap) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text,
              style: TextStyle(color: DashboardTheme.textPale, fontSize: 13)),
          MouseRegion(
            onEnter: (_) => setState(() => _isSwitchHovered = true),
            onExit: (_) => setState(() => _isSwitchHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _isSwitchHovered ? DashboardTheme.textMain : DashboardTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: _isSwitchHovered
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(action),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return _HoverField(
      label: label,
      controller: controller,
      icon: icon,
      isPassword: isPassword,
      isPasswordVisible: _isPasswordVisible,
      onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
    );
  }

  /// SRS-compliant validated field with custom validator, maxLength, keyboardType
  Widget _buildValidatedField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: DashboardTheme.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: DashboardTheme.textPale, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: DashboardTheme.textPale, size: 20),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: DashboardTheme.textMain.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DashboardTheme.textMain.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DashboardTheme.textMain.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: DashboardTheme.primary, width: 1.5),
      ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: GoogleFonts.notoSans(fontSize: 11, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text) {
    return _HoverButton(
      text: text,
      isLoading: _isLoading,
      onTap: _handleAuth,
    );
  }

  Widget _buildHeroTagline() {
    return Positioned(
      top: 140,
      right: 60,
      width: 450,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Manage Your Property,',
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textMain,
                  height: 1.15)), // Tuned to 1.15 for cohesion
          Text('Effortlessly.',
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.primary,
                  height: 1.15)), // Tuned to 1.15 for cohesion
          const SizedBox(
              height: 24), // Increased gap to separate hook from info
          Text(
              'One platform, complete control. Monitor repairs and manage assets with precision.',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: DashboardTheme.textPale, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSeasonStatus() {
    final season = _seasons[_currentSeasonIndex];
    return Positioned(
      bottom: 60,
      right: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: season['accent'].withOpacity(0.8),
                  shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text('${season['name']} — ${season['label']}',
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: season['accent'].withOpacity(0.8),
                  letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildGeometricAccents() {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
              painter: GeometricAccentPainter(accentGold.withOpacity(0.15))),
        ),
      ),
    );
  }
}

class GeometricAccentPainter extends CustomPainter {
  final Color color;
  GeometricAccentPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dashPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double i = 0; i < size.width; i += 100)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), dashPaint);
    for (double i = 0; i < size.height; i += 100)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), dashPaint);
    canvas.drawLine(
        Offset(size.width * 0.7, 40), Offset(size.width * 0.95, 40), paint);
    canvas.drawLine(
        Offset(size.width * 0.7, 48), Offset(size.width * 0.9, 48), paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 40, paint);
    canvas.drawLine(
        Offset(40, size.height * 0.2), Offset(40, size.height * 0.8), paint);
    for (double j = size.height * 0.2; j < size.height * 0.8; j += 40)
      canvas.drawLine(Offset(40, j), Offset(55, j), paint);
    canvas.drawArc(Rect.fromLTWH(size.width * 0.7, size.height * 0.1, 400, 400),
        0, 1.5, false, paint);
    final diamondPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.12, size.height * 0.13)
      ..lineTo(size.width * 0.1, size.height * 0.16)
      ..lineTo(size.width * 0.08, size.height * 0.13)
      ..close();
    canvas.drawPath(diamondPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WeatherPainter extends CustomPainter {
  final String type;
  final Color color;
  final double progress;
  WeatherPainter(
      {required this.type, required this.color, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (type == 'rain')
      _drawRain(canvas, size, paint, time);
    else if (type == 'snow')
      _drawSnow(canvas, size, paint, time);
    else if (type == 'haze') _drawHaze(canvas, size, paint, time);
  }

  void _drawRain(Canvas canvas, Size size, Paint paint, double time) {
    paint.style = PaintingStyle.stroke;
    for (int i = 0; i < 60; i++) {
      double seed = (i * 2.5) % 10.0;
      double speed = 500.0 + (seed * 500.0);
      double length = 4.0 + (seed * 8.0);
      double thickness = 0.4 + (seed * 0.2);
      double windSway = -3.0 - (math.sin(time * 0.4 + i) * 1.5);
      double x =
          (size.width * ((i * 19.3) % 10 / 10.0) + time * 60) % size.width;
      double y =
          (size.height * ((i * 27.7) % 10 / 10.0) + time * speed) % size.height;
      paint.strokeWidth = thickness * 3.0;
      paint.color = color.withOpacity(0.04);
      canvas.drawLine(Offset(x, y), Offset(x + windSway, y + length), paint);
      paint.strokeWidth = thickness;
      paint.color = color.withOpacity(0.35);
      canvas.drawLine(Offset(x, y), Offset(x + windSway, y + length), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size, Paint paint, double time) {
    for (int i = 0; i < 60; i++) {
      double randomSeed = (i * 1.5) % 10.0;
      double speed = 50.0 + (randomSeed * 10);
      double driftWidth = 20.0 + (randomSeed * 5);
      double x = (size.width * ((i * 13.7) % 10 / 10.0) +
              (math.sin(time * 0.8 + i) * driftWidth)) %
          size.width;
      double y =
          (size.height * ((i * 23.3) % 10 / 10.0) + time * speed) % size.height;
      double particleSize = 1.0 + (randomSeed * 0.2);
      canvas.drawCircle(
          Offset(x, y), particleSize, paint..color = color.withOpacity(0.4));
      canvas.drawCircle(Offset(x, y), particleSize + 2.0,
          paint..color = color.withOpacity(0.05));
    }
  }

  void _drawHaze(Canvas canvas, Size size, Paint paint, double time) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 15; i++) {
      double x = (size.width * (i / 15.0) + math.sin(time * 0.5 + i) * 20) %
          size.width;
      double startY = size.height * 0.7;
      double endY = size.height * 0.9;
      Path path = Path();
      path.moveTo(x, startY);
      for (double j = 1; j <= 5; j++) {
        double segmentY = startY + (endY - startY) * (j / 5);
        double offsetX = math.sin(time * 2 + i + j) * 8;
        path.lineTo(x + offsetX, segmentY);
      }
      canvas.drawPath(path, paint..color = color.withOpacity(0.1));
    }
  }

  @override
  bool shouldRepaint(covariant WeatherPainter oldDelegate) => true;
}

class _HoverField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;

  const _HoverField({
    required this.label,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    required this.onTogglePassword,
  });

  @override
  State<_HoverField> createState() => _HoverFieldState();
}

class _HoverFieldState extends State<_HoverField> {
  bool _isHovered = false;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isFocused;
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? DashboardTheme.primary : DashboardTheme.textPale,
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: DashboardTheme.textMain.withOpacity(isActive ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? DashboardTheme.primary.withOpacity(0.5) : DashboardTheme.textMain.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: DashboardTheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.isPassword && !widget.isPasswordVisible,
                style: TextStyle(color: DashboardTheme.textMain, fontSize: 15),
                cursorColor: DashboardTheme.primary,
                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    widget.icon,
                    color: isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                    size: 20,
                  ),
                  // Explicitly disable ALL borders from theme to avoid default gold flash or thick borders
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            widget.isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: isActive ? DashboardTheme.primary.withOpacity(0.7) : DashboardTheme.textPale,
                            size: 18,
                          ),
                          onPressed: widget.onTogglePassword,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;

  const _HoverButton({
    required this.text,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isHovered
                      ? [DashboardTheme.primary, DashboardTheme.primary.withOpacity(0.8)]
                      : [DashboardTheme.primary.withOpacity(0.7), DashboardTheme.primary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: DashboardTheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: DashboardTheme.surface, strokeWidth: 2),
                      )
                    : Text(
                        widget.text,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DashboardTheme.surface,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
