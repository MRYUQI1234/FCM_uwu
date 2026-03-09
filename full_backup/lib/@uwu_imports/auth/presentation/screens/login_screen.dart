import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

// --- Theme Data ---
class LoginTheme {
  final String name;
  final Color bg1;
  final Color bg2;
  final Color accent;
  final Color accentDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color panelBg;
  final Color panelBorder;
  final Color fieldBg;
  final Color fieldBorder;
  final Color scaffoldBg;
  final Color chipColor; // for the picker dot
  final Brightness brightness;

  const LoginTheme({
    required this.name,
    required this.bg1,
    required this.bg2,
    required this.accent,
    required this.accentDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.panelBg,
    required this.panelBorder,
    required this.fieldBg,
    required this.fieldBorder,
    required this.scaffoldBg,
    required this.chipColor,
    this.brightness = Brightness.dark,
  });
}

const List<LoginTheme> kThemes = [
  // 0 - Black Gold (current/default)
  LoginTheme(
    name: 'Black Gold',
    bg1: Color(0xFF0D0D0E),
    bg2: Color(0xFF1A1A1C),
    accent: Color(0xFFC5A059),
    accentDark: Color(0xFF8B7348),
    textPrimary: Colors.white,
    textSecondary: Colors.white54,
    panelBg: Colors.black54,
    panelBorder: Colors.white10,
    fieldBg: Color(0x0DFFFFFF), // white 5%
    fieldBorder: Color(0x14FFFFFF), // white 8%
    scaffoldBg: Colors.black,
    chipColor: Color(0xFFC5A059),
  ),
  // 1 - White Clean
  LoginTheme(
    name: 'White',
    bg1: Color(0xFFF5F5F5),
    bg2: Color(0xFFFFFFFF),
    accent: Color(0xFF333333),
    accentDark: Color(0xFF555555),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF777777),
    panelBg: Color(0xCCFFFFFF), // white 80%
    panelBorder: Color(0x1A000000), // black 10%
    fieldBg: Color(0x0A000000), // black 4%
    fieldBorder: Color(0x14000000), // black 8%
    scaffoldBg: Color(0xFFF5F5F5),
    chipColor: Color(0xFFEEEEEE),
    brightness: Brightness.light,
  ),
  // 2 - White Blue
  LoginTheme(
    name: 'White Blue',
    bg1: Color(0xFFE8EEF4),
    bg2: Color(0xFFF0F4F8),
    accent: Color(0xFF1565C0),
    accentDark: Color(0xFF0D47A1),
    textPrimary: Color(0xFF1A237E),
    textSecondary: Color(0xFF5C6BC0),
    panelBg: Color(0xCCF0F4F8), // frosted white-blue
    panelBorder: Color(0x221565C0), // blue 13%
    fieldBg: Color(0x0A1565C0), // blue 4%
    fieldBorder: Color(0x141565C0), // blue 8%
    scaffoldBg: Color(0xFFE8EEF4),
    chipColor: Color(0xFF1565C0),
    brightness: Brightness.light,
  ),
  // 3 - Orange Blue
  LoginTheme(
    name: 'Orange Blue',
    bg1: Color(0xFF0D1B2A),
    bg2: Color(0xFF1B2838),
    accent: Color(0xFFFF6B35),
    accentDark: Color(0xFFCC5529),
    textPrimary: Color(0xFFE0E7EF),
    textSecondary: Color(0xFF8899AA),
    panelBg: Color(0x880D1B2A), // navy 53%
    panelBorder: Color(0x22FF6B35), // orange 13%
    fieldBg: Color(0x0DFF6B35), // orange 5%
    fieldBorder: Color(0x14FF6B35), // orange 8%
    scaffoldBg: Color(0xFF0D1B2A),
    chipColor: Color(0xFFFF6B35),
  ),
];

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
  final _nameController = TextEditingController();
  final _houseIdController = TextEditingController();
  final _nationalIdController = TextEditingController();
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
  int _currentThemeIndex = 0;

  // Theme-aware color getters
  LoginTheme get _theme => kThemes[_currentThemeIndex];
  Color get _accent => _theme.accent;
  Color get _accentDark => _theme.accentDark;
  Color get _textPrimary => _theme.textPrimary;
  Color get _textSecondary => _theme.textSecondary;
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
      'colors': [const Color(0xFF2C1E12), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFFFFB74D),
      'exposure': 1.8,
      'weather': 'haze',
    },
    {
      'name': 'RAINY',
      'label': 'SOFT & HUMID',
      'colors': [const Color(0xFF1A2226), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFF4DB6AC),
      'exposure': 0.8,
      'weather': 'rain',
    },
    {
      'name': 'WINTER',
      'label': 'CRISP & COLD',
      'colors': [const Color(0xFF141A2F), const Color(0xFF0D0D0E)],
      'accent': const Color(0xFF81D4FA),
      'exposure': 1.3,
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
      if (mounted && !_isPanelOpen) {
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
    _nameController.dispose();
    _houseIdController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _weatherController.dispose();
    _seasonTransitionController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final formKey = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      if (_isLoginMode) {
        // Role-based routing
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isLoading = false);
        if (mounted) {
          final email = _emailController.text.trim().toLowerCase();
          String route = '/3d_model'; // Default for residents

          if (email == 'admin@gmail.com') {
            route = '/juristic';
          } else if (email == 'technician@gmail.com') {
            route = '/technician';
          }

          Navigator.pushReplacementNamed(context, route, arguments: email);
        }
      } else {
        // Quick Success for Sign Up
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Account created successfully!',
                  style: GoogleFonts.kanit()),
              backgroundColor: Colors.green));
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

    return Scaffold(
      backgroundColor: _theme.scaffoldBg,
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
                  child: Container(color: _theme.scaffoldBg.withOpacity(0.01)),
                ),
              ),
            ),
          if (!isMobile && !_isPanelOpen) _buildGeometricAccents(),
          if (!isMobile && !_isPanelOpen) _buildHeroTagline(),
          if (!isMobile) _buildFeatureTicker(),
          if (!isMobile) _buildSeasonStatus(), // Added to bottom-right
          if (!isMobile && !_isPanelOpen) _buildThemeSwitcher(),
          Positioned(
            top: 40,
            left: isMobile ? 24 : 60,
            child: _buildBranding(),
          ),
          if (!isMobile && !_isPanelOpen)
            Positioned(
              right: 60,
              top: 40,
              child: _buildAccessButton(),
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
  }

  Widget _buildBackground(double screenWidth, bool isMobile) {
    return AnimatedBuilder(
      animation: _seasonTransitionController,
      builder: (context, child) {
        final t = _seasonTransitionController.value;
        final currentSeason = _seasons[_currentSeasonIndex];
        final previousSeason = _seasons[_previousSeasonIndex];

        // Season gradient (original dark)
        final seasonColor1 = Color.lerp(
            previousSeason['colors'][0], currentSeason['colors'][0], t)!;
        final seasonColor2 = Color.lerp(
            previousSeason['colors'][1], currentSeason['colors'][1], t)!;

        // Blend season with theme background (0 = pure theme, 1 = pure season)
        final isDarkTheme = _theme.brightness == Brightness.dark;
        final blendFactor = isDarkTheme ? 0.85 : 0.15;
        final List<Color> colors = [
          Color.lerp(_theme.bg1, seasonColor1, blendFactor)!,
          Color.lerp(_theme.bg2, seasonColor2, blendFactor)!,
        ];

        // Adjust model exposure based on theme brightness
        final modelExposure = isDarkTheme ? 0.8 : 1.6;

        return Stack(
          children: [
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: colors)))),
            Positioned.fill(
              child: IgnorePointer(
                child: ModelViewer(
                  key: ValueKey('fcm_house_$_currentThemeIndex'),
                  backgroundColor: Colors.transparent,
                  src: 'assets/models/house.glb',
                  alt: 'FCM House Model',
                  autoRotate: true,
                  autoPlay: true,
                  cameraControls: false,
                  disableZoom: true,
                  exposure: modelExposure,
                  shadowIntensity: isDarkTheme ? 0.2 : 0.6,
                  shadowSoftness: 1.0,
                  rotationPerSecond: '10deg',
                  cameraTarget: 'auto 1m auto',
                  cameraOrbit: '45deg 75deg 80%',
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
              border: Border.all(color: _accent.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.shield_rounded, color: _accent, size: 24),
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
                    color: _textPrimary,
                    letterSpacing: 2)),
            Text('ENTERPRISE QUALITY MANAGEMENT',
                style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: _accent.withOpacity(0.9),
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
                      color: _accent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withOpacity(0.15))),
                  child: Icon(feature['icon'],
                      color: _accent.withOpacity(0.8), size: 26)),
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
                            color: _textPrimary)),
                    const SizedBox(height: 4),
                    Text(feature['desc'],
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: _textSecondary))
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
                  ? [_accent, _accentDark]
                  : [_accentDark, _accent],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(_isAccessButtonHovered ? 0.6 : 0.3),
                blurRadius: _isAccessButtonHovered ? 25 : 20,
                offset: Offset(0, _isAccessButtonHovered ? 10 : 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login_rounded,
                  color: _theme.brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  size: 18),
              const SizedBox(width: 10),
              Text('Sign In',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
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
          color: _theme.panelBg,
          border:
              Border(left: BorderSide(color: _theme.panelBorder, width: 1))),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: _theme.panelBg,
            child: Stack(
              children: [
                if (!isMobile)
                  Positioned(
                    top: 32,
                    right: 32,
                    child: IconButton(
                      onPressed: () => setState(() => _isPanelOpen = false),
                      icon: Icon(Icons.close_rounded,
                          color: _textSecondary, size: 24),
                      style: IconButton.styleFrom(
                          backgroundColor: _accent.withOpacity(0.05)),
                    ),
                  ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: SingleChildScrollView(
                      key: ValueKey(_isLoginMode),
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: _isLoginMode ? 360 : 440),
                        child: _isLoginMode
                            ? _buildLoginForm()
                            : _buildRegisterForm(),
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
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text('Welcome back. Please enter your credentials.',
              style: GoogleFonts.outfit(fontSize: 14, color: _textSecondary)),
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
                  child: Text('Forgot password?',
                      style: TextStyle(color: _accent, fontSize: 13)))),
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
          Text('Resident Registration',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text(
              'Please fill in your real information for identity verification.',
              style: GoogleFonts.outfit(fontSize: 14, color: _textSecondary)),
          const SizedBox(height: 36),
          // Row 1: Full Name + House ID
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                    'Full Name', _nameController, Icons.person_outline,
                    hint: 'e.g. John Smith'),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 130,
                child: _buildField(
                    'House ID', _houseIdController, Icons.home_outlined,
                    hint: 'e.g. 123/45'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: National ID (full width)
          _buildField('National ID (13 digits)', _nationalIdController,
              Icons.badge_outlined,
              hint: 'e.g. 1234567890123',
              keyboardType: TextInputType.number,
              maxLength: 13, customValidator: (value) {
            if (value == null || value.isEmpty) return 'Required';
            if (value.length != 13) return 'Must be exactly 13 digits';
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Digits only';
            return null;
          }),
          const SizedBox(height: 20),
          // Row 3: Phone + Email
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: _buildField(
                    'Phone Number', _phoneController, Icons.phone_outlined,
                    hint: 'e.g. 0812345678', keyboardType: TextInputType.phone),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildField(
                    'Email', _emailController, Icons.email_outlined,
                    hint: 'e.g. john@email.com'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 4: Password
          _buildField('Password', _passwordController, Icons.lock_outline,
              isPassword: true),
          const SizedBox(height: 36),
          _buildPrimaryButton('Confirm Registration'),
          const SizedBox(height: 24),
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
              style: TextStyle(
                  color: _textSecondary.withOpacity(0.6), fontSize: 13)),
          MouseRegion(
            onEnter: (_) => setState(() => _isSwitchHovered = true),
            onExit: (_) => setState(() => _isSwitchHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _isSwitchHovered ? _textPrimary : _accent,
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
      {bool isPassword = false,
      String? hint,
      TextInputType? keyboardType,
      int? maxLength,
      String? Function(String?)? customValidator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textSecondary.withOpacity(0.7))),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: _theme.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _theme.fieldBorder)),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            keyboardType: keyboardType,
            maxLength: maxLength,
            style: TextStyle(color: _textPrimary, fontSize: 15),
            validator: customValidator ??
                (value) => (value == null || value.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: _textSecondary.withOpacity(0.5), size: 20),
              hintText: hint,
              hintStyle: TextStyle(
                  color: _textSecondary.withOpacity(0.3), fontSize: 14),
              counterText: '', // Hide character counter for maxLength
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _textSecondary.withOpacity(0.5),
                          size: 18),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                colors: _isButtonHovered
                    ? [_accent, _accentDark]
                    : [_accentDark, _accent]),
            boxShadow: [
              BoxShadow(
                  color: _accent.withOpacity(_isButtonHovered ? 0.4 : 0.15),
                  blurRadius: _isButtonHovered ? 30 : 15,
                  offset: const Offset(0, 8))
            ]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleAuth,
            borderRadius: BorderRadius.circular(12),
            child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: _theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            strokeWidth: 2))
                    : Text(text,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            letterSpacing: 1))),
          ),
        ),
      ),
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
                  color: _textPrimary,
                  height: 1.15)),
          Text('Effortlessly.',
              textAlign: TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                  height: 1.15)),
          const SizedBox(height: 24),
          Text(
              'One platform, complete control. Monitor repairs and manage assets with precision.',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: _textSecondary.withOpacity(0.6),
                  height: 1.5)),
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
              painter: GeometricAccentPainter(_accent.withOpacity(0.15))),
        ),
      ),
    );
  }

  // --- Theme Switcher ---
  Widget _buildThemeSwitcher() {
    return Positioned(
      bottom: 60,
      left: MediaQuery.of(context).size.width / 2 - 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined,
                color: _textSecondary.withOpacity(0.5), size: 14),
            const SizedBox(width: 10),
            ...List.generate(kThemes.length, (i) {
              final isActive = i == _currentThemeIndex;
              return GestureDetector(
                onTap: () => setState(() => _currentThemeIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                      EdgeInsets.only(right: i < kThemes.length - 1 ? 8 : 0),
                  width: isActive ? 28 : 22,
                  height: isActive ? 28 : 22,
                  decoration: BoxDecoration(
                    color: kThemes[i].chipColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive
                          ? (_theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          : Colors.transparent,
                      width: isActive ? 2.5 : 0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: kThemes[i].chipColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ],
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
    for (double i = 0; i < size.width; i += 100) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), dashPaint);
    }
    for (double i = 0; i < size.height; i += 100) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), dashPaint);
    }
    canvas.drawLine(
        Offset(size.width * 0.7, 40), Offset(size.width * 0.95, 40), paint);
    canvas.drawLine(
        Offset(size.width * 0.7, 48), Offset(size.width * 0.9, 48), paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 40, paint);
    canvas.drawLine(
        Offset(40, size.height * 0.2), Offset(40, size.height * 0.8), paint);
    for (double j = size.height * 0.2; j < size.height * 0.8; j += 40) {
      canvas.drawLine(Offset(40, j), Offset(55, j), paint);
    }
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
    if (type == 'rain') {
      _drawRain(canvas, size, paint, time);
    } else if (type == 'snow')
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
