import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/core/controllers/upload_controller.dart';
import 'package:fcm_app/features/auth/presentation/screens/pin_setup_screen.dart' show PinSetupScreen;

// Wrap to prevent name collision or export issues just in case
typedef DefaultPinSetupScreen = PinSetupScreen;

// Shared Profile View — Used by Admin, Technician & Resident

class ProfileView extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imagePath;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileUpdated;

  const ProfileView({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.imagePath,
    this.onMenuTap,
    this.onProfileUpdated,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  XFile? _pickedImage;
  String? _imagePathOverride;
  final _ts = TranslationService.instance;
  final _uploadCtrl = UploadController.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _nameController.text = widget.name;
    if (oldWidget.email != widget.email) _emailController.text = widget.email;
    if (oldWidget.phone != widget.phone) _phoneController.text = widget.phone;
    if (oldWidget.imagePath != widget.imagePath) {
      setState(() => _imagePathOverride = null);
    }
  }

  Future<void> _pickProfileImage() async {
    if (!_isEditing) return;

    final XFile? image = await _uploadCtrl.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (image != null && mounted) {
      setState(() => _pickedImage = image);
    }
  }

  Widget _buildAvatar() {
    Widget imageWidget;
    if (_pickedImage != null) {
      if (kIsWeb) {
        imageWidget = Image.network(_pickedImage!.path,
            fit: BoxFit.cover, width: 100, height: 100);
      } else {
        imageWidget = Image.file(File(_pickedImage!.path),
            fit: BoxFit.cover, width: 100, height: 100);
      }
    } else {
      final displayPath = _imagePathOverride ?? widget.imagePath;
      if (displayPath.startsWith('http')) {
        imageWidget = Image.network(
          displayPath,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
        );
      } else {
        imageWidget = Image.asset(
          displayPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
        );
      }
    }
    return imageWidget;
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: DashboardTheme.primary.withOpacity(0.2),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : '?',
          style: GoogleFonts.outfit(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: DashboardTheme.primary),
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);

    String? uploadedUri;
    if (_pickedImage != null) {
      // 1. Upload to R2 if a new image was picked
      uploadedUri = await _uploadCtrl.uploadProfilePicture(_pickedImage!);
      if (uploadedUri == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to upload profile picture"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final result = await AuthRepository.instance.updateProfile({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      if (uploadedUri != null) 'picture_uri': uploadedUri,
    });

    if (result['success'] == true && mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
        if (uploadedUri != null) {
          _imagePathOverride = uploadedUri;
        }
        _pickedImage = null;
      });
      widget.onProfileUpdated?.call();
      _showSavedSnackbar(_ts.t('profile_account'));
    } else if (mounted) {
      setState(() => _isSaving = false);
      // Optionally show an error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ts.t('profile_update_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoField(String label, TextEditingController controller,
      {bool enabled = false, IconData? icon, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.notoSans(
                color: DashboardTheme.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: DashboardTheme.textSecondary, fontSize: 14),
          decoration: _inputDecoration(hint ?? label).copyWith(
            prefixIcon: icon != null
                ? Icon(icon, color: DashboardTheme.textPale, size: 20)
                : null,
            prefixIconConstraints:
                icon != null ? BoxConstraints.tight(const Size(48, 20)) : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _ts.currentLanguage,
      builder: (context, lang, _) {
        return Container(
          color: DashboardTheme.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 72, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onMenuTap != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: widget.onMenuTap,
                          child: Icon(Icons.menu_rounded,
                              color: DashboardTheme.primary, size: 28),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _ts.t('profile_account'),
                        style: GoogleFonts.outfit(
                          color: DashboardTheme.textMain,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),
                    if (!_isEditing)
                      IconButton(
                        icon: Icon(Icons.edit_rounded,
                            color: DashboardTheme.primary),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    if (_isEditing)
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: DashboardTheme.textPale),
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _nameController.text = widget.name;
                            _emailController.text = widget.email;
                            _phoneController.text = widget.phone;
                          });
                        },
                      ),
                    if (_isEditing)
                      _isSaving
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: DashboardTheme.primary)),
                            )
                          : IconButton(
                              icon: Icon(Icons.check_rounded,
                                  color: DashboardTheme.success),
                              onPressed: _saveProfileChanges,
                            ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _ts.t('profile_subtitle'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: DashboardTheme.textPale,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        DashboardTheme.primary.withOpacity(0.3),
                                    width: 3),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipOval(child: _buildAvatar()),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: DashboardTheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: DashboardTheme.primary
                                            .withOpacity(0.5)),
                                  ),
                                  child: Icon(Icons.camera_alt_rounded,
                                      color:
                                          DashboardTheme.primary.withOpacity(0.6),
                                      size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: DashboardTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: DashboardTheme.primary.withOpacity(0.2)),
                          ),
                          child: Text(
                            widget.role,
                            style: GoogleFonts.notoSans(
                                color: DashboardTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text,
                          style: GoogleFonts.notoSans(
                            color: DashboardTheme.textMain,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text,
                          style: GoogleFonts.notoSans(
                              color: DashboardTheme.textSecondary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                              _ts.t('profile_name'), _nameController,
                              enabled: _isEditing, icon: Icons.person_rounded),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildInfoField(
                              _ts.t('profile_email'), _emailController,
                              enabled: _isEditing, icon: Icons.email_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildInfoField(_ts.t('profile_phone'), _phoneController,
                        enabled: _isEditing, icon: Icons.phone_rounded),
                    const SizedBox(height: 32),
                    const SizedBox(height: 32),
                  ],
                ),
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _HoverActionCard(
                          title: _ts.t('change_password'),
                          icon: Icons.lock_outline_rounded,
                          onTap: () => _showChangePasswordDialog(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _HoverActionCard(
                          title: _ts.t('change_pin'),
                          icon: Icons.pin_outlined,
                          onTap: () => _showChangePinDialog(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePinDialog() {
    // Navigating to the existing PinSetupScreen instead of showing a dialog
    // We pass an empty targetRoute to signal that it should pop instead of replace.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const DefaultPinSetupScreen(targetRoute: ''),
      ),
    ).then((changed) {
      if (changed == true) {
        _showSavedSnackbar(_ts.t('change_pin'));
        widget.onProfileUpdated?.call();
      }
    });
  }

  void _showChangePasswordDialog() {
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    String? errorMessage;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: DashboardTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: DashboardTheme.border)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ts.t('change_password'),
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(errorMessage!,
                                    style: GoogleFonts.kanit(
                                        color: Colors.redAccent,
                                        fontSize: 14))),
                          ],
                        ),
                      ),
                    Text(_ts.t('new_password'),
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("ความยาวอย่างน้อย 8 ตัวอักษร มีตัวพิมพ์เล็กและตัวพิมพ์ใหญ่",
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.textPale,
                            fontSize: 11)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: newPwCtrl,
                        autofocus: true,
                        obscureText: true,
                        style: TextStyle(
                            color: DashboardTheme.textMain, fontSize: 14),
                        decoration: _inputDecoration(_ts.t('new_password'))),
                    const SizedBox(height: 20),
                    Text(_ts.t('confirm_password'),
                        style: GoogleFonts.notoSans(
                            color: DashboardTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: confirmPwCtrl,
                        obscureText: true,
                        style: TextStyle(
                            color: DashboardTheme.textMain, fontSize: 14),
                        decoration:
                            _inputDecoration(_ts.t('confirm_password'))),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                            child: TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(_ts.t('cancel_action'),
                                    style: GoogleFonts.notoSans(
                                        color: DashboardTheme.textPale)))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final newPw = newPwCtrl.text.trim();
                              final confirmPw = confirmPwCtrl.text.trim();
                              if (newPw.length < 8) {
                                setDialogState(() =>
                                    errorMessage = _ts.t('password_too_short'));
                                return;
                              }
                              // Frontend-side matching before sending to backend to explicitly guide user
                              if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z]).{8,}$').hasMatch(newPw)) {
                                setDialogState(() =>
                                    errorMessage = "รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร มีตัวพิมพ์เล็กและพิมพ์ใหญ่");
                                return;
                              }
                              if (newPw != confirmPw) {
                                setDialogState(() =>
                                    errorMessage = _ts.t('password_mismatch'));
                                return;
                              }
                              final result = await AuthRepository.instance
                                  .updateProfile({'password': newPw});
                              if (result['success'] == true) {
                                Navigator.pop(ctx);
                                _showSavedSnackbar(_ts.t('change_password'));
                                widget.onProfileUpdated?.call();
                              } else {
                                setDialogState(() => errorMessage =
                                    result['error'] ?? 'Update failed');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: Text(_ts.t('save_changes'),
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: "$hint...",
      hintStyle: TextStyle(color: DashboardTheme.textPale),
      filled: true,
      fillColor: DashboardTheme.surfaceSecondary,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DashboardTheme.primary)),
    );
  }

  void _showSavedSnackbar(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: DashboardTheme.success, size: 18),
          const SizedBox(width: 10),
          Text('$label ${_ts.t("updated_success")}',
              style: GoogleFonts.notoSans(
                  color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: DashboardTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _HoverActionCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  _HoverActionCard({required this.title, this.icon, this.onTap});
  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    final accentColor = DashboardTheme.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: DashboardTheme.surface.withOpacity(_isHovered ? 1.0 : 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _isHovered
                    ? accentColor.withOpacity(0.4)
                    : DashboardTheme.border.withOpacity(0.5)),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                        color: accentColor.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.icon != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                      color: _isHovered
                          ? accentColor.withOpacity(0.1)
                          : DashboardTheme.background,
                      shape: BoxShape.circle),
                  child: Icon(widget.icon,
                      color: _isHovered
                          ? accentColor
                          : DashboardTheme.textSecondary,
                      size: 20),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.notoSans(
                    color: _isHovered
                        ? DashboardTheme.textMain
                        : DashboardTheme.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
                child: Text(widget.title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
