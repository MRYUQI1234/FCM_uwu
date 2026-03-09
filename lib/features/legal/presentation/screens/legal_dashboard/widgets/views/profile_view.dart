import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/core/data/auth_repository.dart';

// Shared Profile View — Used by Admin, Technician & Resident

class ProfileView extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imagePath;
  final VoidCallback? onMenuTap;

  const ProfileView({
    super.key,
    this.name = "Admin Vivorn",
    this.email = "admin.vivorn@gmail.com",
    this.phone = "+66 88 777 9999",
    this.role = "Admin",
    this.imagePath = 'assets/resident_profile.png',
    this.onMenuTap,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String _name;
  late String _email;
  late String _phone;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final _ts = TranslationService.instance;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _phone = widget.phone;
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _name = widget.name;
    if (oldWidget.email != widget.email) _email = widget.email;
    if (oldWidget.phone != widget.phone) _phone = widget.phone;
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (image != null && mounted) {
        setState(() => _pickedImage = image);
        _showSavedSnackbar(_ts.t('profile_name'));
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
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
      imageWidget = Image.asset(
        widget.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: DashboardTheme.primary.withOpacity(0.2),
          child: Center(
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: DashboardTheme.primary),
            ),
          ),
        ),
      );
    }
    return imageWidget;
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
                          _name,
                          style: GoogleFonts.notoSans(
                            color: DashboardTheme.textMain,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: GoogleFonts.notoSans(
                              color: DashboardTheme.textSecondary,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Row(
                  children: [
                    Expanded(
                      child: _HoverInputField(
                        label: _ts.t('profile_name'),
                        value: _name,
                        onEdit: () => _showEditDialog(_ts.t('profile_name'),
                            _name, (v) => setState(() => _name = v)),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _HoverInputField(
                        label: _ts.t('profile_email'),
                        value: _email,
                        onEdit: () => _showEditDialog(_ts.t('profile_email'),
                            _email, (v) => setState(() => _email = v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _HoverInputField(
                  label: _ts.t('profile_phone'),
                  value: _phone,
                  onEdit: () => _showEditDialog(_ts.t('profile_phone'), _phone,
                      (v) => setState(() => _phone = v)),
                ),
                const SizedBox(height: 32),
                _HoverActionCard(
                  title: _ts.t('change_password'),
                  icon: Icons.lock_outline_rounded,
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(
      String label, String currentValue, ValueChanged<String> onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: DashboardTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: DashboardTheme.border),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${_ts.t('edit_dialog_title')} $label",
                    style: GoogleFonts.notoSans(
                        color: DashboardTheme.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Text(label,
                    style: GoogleFonts.notoSans(
                        color: DashboardTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style:
                      TextStyle(color: DashboardTheme.textMain, fontSize: 14),
                  decoration: _inputDecoration(label),
                ),
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
                          final v = controller.text.trim();
                          if (v.isNotEmpty) {
                            onSave(v);
                            // Determine field key for API
                            final nameLabel = _ts.t('profile_name');
                            final emailLabel = _ts.t('profile_email');
                            final phoneLabel = _ts.t('profile_phone');
                            String? apiKey;
                            if (label == nameLabel) apiKey = 'name';
                            if (label == emailLabel) apiKey = 'email';
                            if (label == phoneLabel) apiKey = 'phone';
                            if (apiKey != null) {
                              await AuthRepository.instance
                                  .updateProfile({apiKey: v});
                            }
                          }
                          Navigator.pop(ctx);
                          _showSavedSnackbar(label);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: DashboardTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 16)),
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

class _HoverInputField extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  _HoverInputField(
      {required this.label, required this.value, required this.onEdit});
  @override
  State<_HoverInputField> createState() => _HoverInputFieldState();
}

class _HoverInputFieldState extends State<_HoverInputField> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.notoSans(
                color: DashboardTheme.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onEdit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _hovered
                    ? DashboardTheme.surface
                    : DashboardTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _hovered
                        ? DashboardTheme.primary.withOpacity(0.4)
                        : DashboardTheme.border),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                            color: DashboardTheme.primary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(widget.value,
                          style: GoogleFonts.notoSans(
                              color: DashboardTheme.textSecondary,
                              fontSize: 14))),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovered ? 1.0 : 0.3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _hovered
                              ? DashboardTheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.edit_rounded,
                          color: _hovered
                              ? DashboardTheme.primary
                              : DashboardTheme.textPale,
                          size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
