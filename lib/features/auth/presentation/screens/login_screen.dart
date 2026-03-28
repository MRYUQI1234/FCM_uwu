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

  final _phoneController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoginMode = true; // Added back for in-place toggle
  bool _isPanelOpen = false;
  bool _isPasswordVisible = false;
  String? _errorMessage; // Inline error message above buttons

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

    _phoneController.dispose();
    _weatherController.dispose();
    _seasonTransitionController.dispose();
    super.dispose();
  }

  String _statusCodeToMessage(String? statusCode) {
    debugPrint("Authentication error : $statusCode");

    if (statusCode == null) {
      return "Cannot connect to the server. Please contract juristic person for more informations.";
    }

    switch (statusCode) {
      case 'INVALID_CREDENTIALS':
        return 'Email or password is incorrect';
      //ไม่พบเลขบัตรประชาชน *ยังไม่ได้เพิ่ม passport
      case 'ID_NOT_FOUND':
        return 'ID card number is incorrect, please try again\nor contract juristic person.';
      //อีเมลซ้ำ
      case 'ALREADY_REGISTERED':
        return 'Email is already registered, please try again with new one.';
      default:
        return 'An error has occured, please try again';
    }
  }

  Future<void> _handleAuth() async {
    final formKey = _isLoginMode ? _loginFormKey : _registerFormKey;
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Clear previous error
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      //Signin
      if (_isLoginMode) {
        final result = await AuthRepository.instance.login(email, password);
        setState(() => _isLoading = false);
        if (result['success']) {
          if (mounted) {
            final user = result['user'];
            final role = user != null ? user['role'] : '';
            final statusCode = result['status_code'];

            // Determine target dashboard route based on role
            String targetRoute;
            if (role == 'JURISTIC') {
              targetRoute = '/legal';
            } else if (role == 'TECHNICIAN') {
              targetRoute = '/technician';
            } else {
              targetRoute = '/3d_model';
            }

            // If PIN is not set, redirect to PIN setup first
            if (statusCode == 'REQUIRE_PIN_SETUP') {
              Navigator.pushReplacementNamed(
                context,
                '/pin-setup',
                arguments: targetRoute,
              );
            } else {
              Navigator.pushReplacementNamed(context, targetRoute);
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = _statusCodeToMessage(result['status_code']);
            });
          }
        }
      } else {
        // Sign Up
        final result = await AuthRepository.instance.register(
          nationalId: _idCardController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (result['success']) {
          // v4.1: No PIN setup on signup. Just redirect to login.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('ลงทะเบียนสำเร็จ! กรุณาลงชื่อเข้าใช้',
                    style: GoogleFonts.kanit()),
                backgroundColor: Colors.green));
            _idCardController.clear();
            _nameController.clear();
            _phoneController.clear();
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            setState(() {
              _isLoginMode = true;
              _errorMessage = null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = _statusCodeToMessage(result['status_code']);
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 950;

    // No longer auto-opening the panel on mobile based on USER REQUEST.
    // Users start with the 3D model and taglines and must click "Sign In" to proceed.

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: DashboardTheme.background,
          body: Stack(
            children: [
              _buildBackground(screenWidth, isMobile),
              // Interaction Shield (Placed above the background/model but below UI)
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
              if (!_isPanelOpen) _buildGeometricAccents(),
              if (!_isPanelOpen) _buildHeroTagline(isMobile),
              if (!isMobile) _buildFeatureTicker(),
              if (!_isPanelOpen)
                _buildSeasonStatus(isMobile), // Added to bottom-right
              Positioned(
                top: 40,
                left: isMobile ? 24 : 60,
                child: _buildBranding(),
              ),
              // Mobile: Access button at bottom center (80% width)
              if (isMobile && !_isPanelOpen)
                Positioned(
                  bottom: 100, // Offset from bottom border
                  left: screenWidth * 0.1,
                  right: screenWidth * 0.1,
                  child: _buildAccessButton(isFullWidth: true),
                ),
              // Header Controls
              if (!_isPanelOpen)
                Positioned(
                  right: isMobile ? 24 : 60,
                  top: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildThemeToggle(),
                      if (!isMobile) ...[
                        const SizedBox(width: 20),
                        _buildAccessButton(),
                      ],
                    ],
                  ),
                ),
              // Theme toggle for mobile persistent top-right when panel is open
              if (isMobile && _isPanelOpen)
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
                right: _isPanelOpen ? 0 : (isMobile ? -screenWidth : -500),
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
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
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

        return Stack(
          children: [
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.5,
                            colors: DashboardTheme.isDarkMode.value
                                ? colors
                                : [
                                    DashboardTheme.background,
                                    DashboardTheme.surfaceSecondaryLight
                                  ])))),
            // 3D Model
            Positioned.fill(
              child: IgnorePointer(
                child: ModelViewer(
                  key: const ValueKey('fcm_house_vivorn'),
                  backgroundColor: Colors.transparent,
                  src: 'assets/models/Vivorn7.8.glb',
                  alt: 'Vivorn Smart House',
                  autoRotate: true,
                  autoPlay: true,
                  cameraControls: false,
                  disableZoom: true,
                  exposure: (lerpDouble(
                        previousSeason['exposure'] as double,
                        currentSeason['exposure'] as double,
                        t,
                      ) ??
                      1.0),
                  shadowIntensity: 1.0,
                  shadowSoftness: 1.0,
                  rotationPerSecond: '10deg',
                  cameraTarget: 'auto 1.2m auto',
                  cameraOrbit: '225deg 80deg 105%',
                  maxCameraOrbit: 'auto 85deg auto',
                ),
              ),
            ),
            // Loading overlay — fades away after model initializes
            _ModelLoadingOverlay(isDark: DashboardTheme.isDarkMode.value),
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

  Widget _buildAccessButton({bool isFullWidth = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isAccessButtonHovered = true),
      onExit: (_) => setState(() => _isAccessButtonHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isPanelOpen = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
              horizontal: isFullWidth ? 40 : 24, vertical: 16),
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
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_rounded, color: Colors.black, size: 20),
              const SizedBox(width: 12),
              Text('Sign In',
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 1.5)),
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
                // X close button — always visible as per USER REQUEST
                if (true) // Just keeping structural consistency
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
                          color: _isCloseHovered
                              ? accentGold
                              : DashboardTheme.textPale,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: DashboardTheme.textMain
                              .withOpacity(_isCloseHovered ? 0.15 : 0.05),
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
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Welcome back. Please enter your credentials.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 48),
          _buildValidatedField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter email';
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(v)) {
                return 'Invalid email format';
              }
              if (!RegExp(
                      r'@(gmail.com|outlook.com|hotmail.com|yahoo.com|vivorn.com)$')
                  .hasMatch(v)) {
                return 'Email must be a valid email addresses. (ex. gmail.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildValidatedField(
            label: 'Password',
            controller: _passwordController,
            icon: Icons.lock_outline,
            isPassword: true,
            isLastField: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'Password must be at least 8 characters';
              if (!RegExp('^(?=.*[a-z])(?=.*[A-Z]).{8}').hasMatch(v)) {
                return 'Password must contain at least one\nuppercase letter and one lowercase letter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text('Forgot password?',
                      style: TextStyle(color: accentGold, fontSize: 13)))),
          // Inline error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: GoogleFonts.kanit(
                            fontSize: 13, color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildPrimaryButton('Sign In'),
          const SizedBox(height: 32),
          _buildSwitchMode(
              'Don\'t have an account?',
              'Sign Up',
              () => setState(() {
                    _isLoginMode = false;
                    _errorMessage = null;
                  })),
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
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Create an account to start managing assets.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 36),

          // SRS: 13-digit National ID Card
          _buildValidatedField(
            label: 'National ID (13 Digits)',
            controller: _idCardController,
            icon: Icons.credit_card_rounded,
            maxLength: 13,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please enter your national ID';
              if (v.length != 13) return 'National ID must be 13 digits';
              if (!RegExp(r'^[0-9]{13}').hasMatch(v)) {
                return 'National ID must be numbers only';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildValidatedField(
            label: 'Email',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter email';
              if (!v.contains('@')) return 'Invalid email format';
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(v)) {
                return 'Invalid email format';
              }
              if (!RegExp(
                      r'@(gmail.com|outlook.com|hotmail.com|yahoo.com|vivorn.com)$')
                  .hasMatch(v)) {
                return 'Email must be a valid email addresses. (ex. gmail.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // SRS: Phone (10 digits)
          _buildValidatedField(
            label: 'Phone Number',
            controller: _phoneController,
            icon: Icons.phone_rounded,
            maxLength: 10,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter phone number';
              if (!RegExp(r'^[0-9]{10}').hasMatch(v)) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildValidatedField(
            label: 'Password',
            controller: _passwordController,
            icon: Icons.lock_outline,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 8) return 'Password must be at least 8 characters';
              if (!RegExp('^(?=.*[a-z])(?=.*[A-Z]).{8}').hasMatch(v)) {
                return 'Password must contain at least one\nuppercase letter and one lowercase letter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // SRS: Confirm Password
          _buildValidatedField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            icon: Icons.lock_outline,
            isPassword: true,
            isLastField: true,
            validator: (v) {
              if (v == null || v.isEmpty)
                return 'Please re-enter your password';
              if (v != _passwordController.text)
                return "Password does not match";
              return null;
            },
          ),
          // Inline error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: GoogleFonts.kanit(
                            fontSize: 13, color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          _buildPrimaryButton('Sign Up'),
          const SizedBox(height: 32),
          _buildSwitchMode(
              'Already have an account?',
              'Sign In',
              () => setState(() {
                    _isLoginMode = true;
                    _errorMessage = null;
                  })),
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
                  color: _isSwitchHovered
                      ? DashboardTheme.textMain
                      : DashboardTheme.primary,
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

  /// SRS-compliant validated field with custom validator, maxLength, keyboardType
  /// Panel always has dark background, so text/labels use white tones.
  Widget _buildValidatedField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool isLastField = false,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction:
              isLastField ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: isLastField ? (_) => _handleAuth() : null,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white38,
                        size: 20),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentGold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle:
                GoogleFonts.notoSans(fontSize: 11, color: Colors.redAccent),
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

  Widget _buildHeroTagline(bool isMobile) {
    return Positioned(
      top: isMobile ? 120 : 140,
      left: isMobile ? 24 : null, // Left alignment on mobile looks better
      right: isMobile ? 24 : 60,
      width: isMobile ? null : 450,
      child: Column(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text('Manage Your Property,',
              textAlign: isMobile ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textMain,
                  height: 1.15)), // Tuned to 1.15 for cohesion
          Text('Effortlessly.',
              textAlign: isMobile ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.playfairDisplay(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.primary,
                  height: 1.15)), // Tuned to 1.15 for cohesion
          const SizedBox(
              height: 24), // Increased gap to separate hook from info
          Text(
              'One platform, complete control. Monitor repairs and manage assets with precision.',
              textAlign: isMobile ? TextAlign.left : TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: isMobile ? 14 : 15,
                  color: DashboardTheme.textPale,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSeasonStatus(bool isMobile) {
    final season = _seasons[_currentSeasonIndex];
    return Positioned(
      bottom: isMobile ? 40 : 60,
      right: isMobile ? 24 : 60,
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
                  fontSize: isMobile ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: season['accent'].withOpacity(0.8),
                  letterSpacing: isMobile ? 1 : 2)),
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

class _HoverField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  final VoidCallback onTogglePassword;

  const _HoverField({
    required this.label,
    required this.controller,
    required this.icon,
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
                color:
                    isActive ? DashboardTheme.primary : DashboardTheme.textPale,
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color:
                    DashboardTheme.textMain.withOpacity(isActive ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? DashboardTheme.primary.withOpacity(0.5)
                      : DashboardTheme.textMain.withOpacity(0.08),
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
                obscureText: false,
                style: TextStyle(color: DashboardTheme.textMain, fontSize: 15),
                cursorColor: DashboardTheme.primary,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    widget.icon,
                    color: isActive
                        ? DashboardTheme.primary
                        : DashboardTheme.textPale,
                    size: 20,
                  ),
                  // Explicitly disable ALL borders from theme to avoid default gold flash or thick borders
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  suffixIcon: null,
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
                      ? [
                          DashboardTheme.primary,
                          DashboardTheme.primary.withOpacity(0.8)
                        ]
                      : [
                          DashboardTheme.primary.withOpacity(0.7),
                          DashboardTheme.primary.withOpacity(0.8)
                        ],
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
                        child: CircularProgressIndicator(
                            color: DashboardTheme.surface, strokeWidth: 2),
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

// ── Loading overlay: hides ModelViewer until WebGL warms up ──────────────────
class _ModelLoadingOverlay extends StatefulWidget {
  final bool isDark;
  const _ModelLoadingOverlay({required this.isDark});

  @override
  State<_ModelLoadingOverlay> createState() => _ModelLoadingOverlayState();
}

class _ModelLoadingOverlayState extends State<_ModelLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Wait for WebGL to initialize then fade out
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: IgnorePointer(
          ignoring: _opacity.value < 0.01,
          child: Container(
            color: widget.isDark
                ? const Color(0xFF0D0D0E)
                : const Color(0xFFF5F5F5),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFC5A059),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
