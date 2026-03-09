import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

// ═══════════════════════════════════════════════════════════
// Shared Profile View — Used by Admin, Technician & Resident
// Fully editable with hover effects and live state
// ═══════════════════════════════════════════════════════════

class ProfileView extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imagePath;

  const ProfileView({
    super.key,
    this.name = "Admin Zeta",
    this.email = "admin.zeta@gmail.com",
    this.phone = "+66 88 777 9999",
    this.role = "Admin",
    this.imagePath = 'assets/resident_profile.png',
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
      if (image != null && mounted) {
        setState(() => _pickedImage = image);
        _showSavedSnackbar('Profile photo');
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  Widget _buildAvatar() {
    Widget imageWidget;
    if (_pickedImage != null) {
      if (kIsWeb) {
        imageWidget = Image.network(_pickedImage!.path, fit: BoxFit.cover, width: 100, height: 100);
      } else {
        imageWidget = Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: 100, height: 100);
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
              style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, color: DashboardTheme.primary),
            ),
          ),
        ),
      );
    }
    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account",
              style: GoogleFonts.notoSans(
                color: DashboardTheme.textMain,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 48),

            // Avatar & Name Header
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
                            border: Border.all(color: DashboardTheme.primary.withOpacity(0.3), width: 3),
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
                              border: Border.all(color: DashboardTheme.primary.withOpacity(0.5)),
                            ),
                            child: Icon(Icons.camera_alt_rounded, color: DashboardTheme.primary.withOpacity(0.6), size: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: DashboardTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DashboardTheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.role,
                        style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
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
                      style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Form Fields: Name & Email
            Row(
              children: [
                Expanded(
                  child: _HoverInputField(
                    label: "Name",
                    value: _name,
                    onEdit: () => _showEditDialog("Name", _name, (v) => setState(() => _name = v)),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _HoverInputField(
                    label: "Email",
                    value: _email,
                    onEdit: () => _showEditDialog("Email", _email, (v) => setState(() => _email = v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _HoverInputField(
              label: "Phone",
              value: _phone,
              onEdit: () => _showEditDialog("Phone", _phone, (v) => setState(() => _phone = v)),
            ),
            const SizedBox(height: 32),

            // Action Cards: Change Password & Transfer Ownership
            Row(
              children: [
                Expanded(
                  child: _HoverActionCard(
                    title: "Change password",
                    icon: Icons.lock_outline_rounded,
                    onTap: () => _showEditDialog("Password", "", (_) {}, isPassword: true),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _HoverActionCard(
                    title: "Transfer ownership",
                    icon: Icons.person_add_alt_1_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Danger Zone: Delete Account
            _HoverActionCard(
              title: "Delete account",
              content: Text(
                "Contact our support team to process the deletion of your account.",
                style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 12),
              ),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String label, String currentValue, ValueChanged<String> onSave, {bool isPassword = false}) {
    final controller = TextEditingController(text: isPassword ? "" : currentValue);

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
                Text(
                  isPassword ? "Change Password" : "Edit $label",
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPassword ? "New Password" : label,
                  style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: isPassword,
                  style: TextStyle(color: DashboardTheme.textMain, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Enter your ${label.toLowerCase()}...",
                    hintStyle: TextStyle(color: DashboardTheme.textPale),
                    filled: true,
                    fillColor: DashboardTheme.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: DashboardTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: DashboardTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: DashboardTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("CANCEL", style: GoogleFonts.notoSans(color: DashboardTheme.textPale)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newValue = controller.text.trim();
                          if (newValue.isNotEmpty) {
                            onSave(newValue);
                          }
                          Navigator.pop(ctx);
                          _showSavedSnackbar(label);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DashboardTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text("SAVE CHANGES", style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
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

  void _showSavedSnackbar(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: DashboardTheme.success, size: 18),
            const SizedBox(width: 10),
            Text(
              '$label updated successfully',
              style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: DashboardTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ───────────────────────────────────────
// Hover Input Field
// ───────────────────────────────────────
class _HoverInputField extends StatefulWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _HoverInputField({required this.label, required this.value, required this.onEdit});

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
        Text(
          widget.label,
          style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 16, fontWeight: FontWeight.w500),
        ),
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
                color: _hovered ? DashboardTheme.surface : DashboardTheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered ? DashboardTheme.primary.withOpacity(0.4) : DashboardTheme.border,
                ),
                boxShadow: _hovered
                    ? [BoxShadow(color: DashboardTheme.primary.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value,
                      style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovered ? 1.0 : 0.3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hovered ? DashboardTheme.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: _hovered ? DashboardTheme.primary : DashboardTheme.textPale,
                        size: 16,
                      ),
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

// ───────────────────────────────────────
// Hover Action Card
// ───────────────────────────────────────
class _HoverActionCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget? content;
  final bool isDanger;
  final VoidCallback? onTap;

  const _HoverActionCard({
    required this.title,
    this.icon,
    this.content,
    this.isDanger = false,
    this.onTap,
  });

  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDanger ? DashboardTheme.error : DashboardTheme.primary;

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
            color: widget.isDanger
                ? DashboardTheme.error.withOpacity(_isHovered ? 0.08 : 0.04)
                : DashboardTheme.surface.withOpacity(_isHovered ? 1.0 : 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? accentColor.withOpacity(0.4)
                  : DashboardTheme.border.withOpacity(0.5),
            ),
            boxShadow: _isHovered
                ? [BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))]
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
                    color: _isHovered ? accentColor.withOpacity(0.1) : DashboardTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHovered ? accentColor : DashboardTheme.textSecondary,
                    size: 20,
                  ),
                ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.notoSans(
                  color: widget.isDanger
                      ? DashboardTheme.error
                      : (_isHovered ? DashboardTheme.textMain : DashboardTheme.textSecondary),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(widget.title),
              ),
              if (widget.content != null) ...[
                const SizedBox(height: 8),
                widget.content!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
