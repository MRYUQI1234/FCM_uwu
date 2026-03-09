import 'dart:ui';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_painters.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:image_picker/image_picker.dart';

/// FE-05: Add / Edit personnel overlay (SRS Compliant)
class AddPersonnelOverlay extends StatefulWidget {
  final Map<String, dynamic>? existingPersonnel; // null = add mode, non-null = edit mode
  final VoidCallback onDismiss;
  final Function(Map<String, dynamic>) onSave;

  const AddPersonnelOverlay({
    super.key,
    this.existingPersonnel,
    required this.onDismiss,
    required this.onSave,
  });

  @override
  State<AddPersonnelOverlay> createState() => _AddPersonnelOverlayState();
}

class _AddPersonnelOverlayState extends State<AddPersonnelOverlay> {
  late TextEditingController _nameController;
  late TextEditingController _idCardController;
  late TextEditingController _phoneController;
  late TextEditingController _lineController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _birthplaceController;
  late TextEditingController _bioController;

  String _selectedType = 'technician';
  String? _errorMessage;
  bool _showIdCard = false;
  String? _generatedEmployeeId;
  XFile? _pickedFile;
  bool _isPhotoHovered = false;

  // Radar Chart Stats
  double _statAir = 0.5;
  double _statPower = 0.5;
  double _statPipe = 0.5;
  double _statBuild = 0.5;
  double _statPaint = 0.5;

  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.existingPersonnel != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPersonnel;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _idCardController = TextEditingController(text: p?['idCard'] ?? '');
    _phoneController = TextEditingController(text: p?['phone'] ?? '');
    _lineController = TextEditingController(text: p?['line'] ?? '');
    _emailController = TextEditingController(text: p?['email'] ?? '');
    _ageController = TextEditingController(text: p?['age']?.toString() ?? '');
    _heightController = TextEditingController(text: p?['height'] ?? '');
    _birthplaceController = TextEditingController(text: p?['birthplace'] ?? '');
    _bioController = TextEditingController(text: p?['bio'] ?? '');

    if (p != null) {
      _selectedType = p['type'] ?? 'technician';
      _generatedEmployeeId = p['id'];
      
      final stats = p['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        _statAir = (stats['AIR'] ?? 0.5).toDouble();
        _statPower = (stats['POWER'] ?? 0.5).toDouble();
        _statPipe = (stats['PIPE'] ?? 0.5).toDouble();
        _statBuild = (stats['BUILD'] ?? 0.5).toDouble();
        _statPaint = (stats['PAINT'] ?? 0.5).toDouble();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _lineController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _birthplaceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  String _generateEmployeeId() {
    final prefix = _selectedType == 'technician' ? 'TECH' : 'ADMIN';
    final num = DateTime.now().millisecondsSinceEpoch % 10000;
    return '$prefix-${num.toString().padLeft(4, '0')}';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _pickedFile = image);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _validate() {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "กรุณากรอกชื่อ-นามสกุล");
      return;
    }
    if (_idCardController.text.trim().length != 13) {
      setState(() => _errorMessage = "กรุณากรอกหมายเลขบัตรประชาชนให้ครบ 13 หลัก");
      return;
    }
    if (!RegExp(r'^\d{13}$').hasMatch(_idCardController.text.trim())) {
      setState(() => _errorMessage = "หมายเลขบัตรประชาชนต้องเป็นตัวเลขเท่านั้น");
      return;
    }
    if (_phoneController.text.trim().length != 10) {
      setState(() => _errorMessage = "กรุณากรอกเบอร์โทรศัพท์เป็นตัวเลข 10 หลัก");
      return;
    }

    // Check duplicates in existing data
    if (!_isEditMode) {
      final existing = DashboardData.technicians;
      final duplicate = existing.any((t) => t['idCard'] == _idCardController.text.trim());
      if (duplicate) {
        setState(() => _errorMessage = "มีบุคลากรที่มีหมายเลขประจำตัวนี้อยู่แล้ว กรุณาตรวจสอบอีกครั้ง");
        return;
      }
    }

    // Generate ID and show preview
    _generatedEmployeeId ??= _generateEmployeeId();
    setState(() => _showIdCard = true);
  }

  void _confirmSave() {
    widget.onSave({
      'name': _nameController.text.trim(),
      'id': _generatedEmployeeId,
      'idCard': _idCardController.text.trim(),
      'phone': _phoneController.text.trim(),
      'line': _lineController.text.trim(),
      'email': _emailController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 25,
      'height': _heightController.text.trim().isEmpty ? "170 cm" : _heightController.text.trim(),
      'birthplace': _birthplaceController.text.trim(),
      'bio': _bioController.text.trim(),
      'type': _selectedType,
      'role': _selectedType == 'technician' ? 'TECHNICIAN' : 'VILLAGE ADMIN',
      'isActive': true,
      'image': _pickedFile != null ? _pickedFile!.path : (widget.existingPersonnel?['image'] ?? 'assets/resident_profile.png'),
      'icon': _selectedType == 'technician' ? Icons.engineering_rounded : Icons.admin_panel_settings_rounded,
      'abilities': _bioController.text.isNotEmpty ? [_bioController.text.split(' ').first] : ['General'],
      'stats': {
        'AIR': _statAir,
        'POWER': _statPower,
        'PIPE': _statPipe,
        'BUILD': _statBuild,
        'PAINT': _statPaint,
      },
    });
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dismiss on content tap
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showIdCard ? _buildIdCardPreview() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      key: const ValueKey('form'),
      width: 560,
      constraints: const BoxConstraints(maxHeight: 700),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 60)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode ? "EDIT PERSONNEL" : "ADD NEW PERSONNEL",
                      style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditMode ? "แก้ไขข้อมูลบุคลากร" : "เพิ่มบุคลากรใหม่",
                      style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Material(
                  color: DashboardTheme.surfaceSecondary,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: widget.onDismiss,
                    icon: Icon(Icons.close_rounded, color: DashboardTheme.textMain, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Profile Photo with Hover Effect
            Center(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isPhotoHovered = true),
                onExit: (_) => setState(() => _isPhotoHovered = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedScale(
                    scale: _isPhotoHovered ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isPhotoHovered ? DashboardTheme.primary : DashboardTheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: _isPhotoHovered ? [
                              BoxShadow(color: DashboardTheme.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                            ] : [],
                          ),
                          child: ClipOval(
                            child: _pickedFile != null
                                ? (kIsWeb 
                                    ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                                    : Image.file(File(_pickedFile!.path), fit: BoxFit.cover))
                                : (widget.existingPersonnel?['image'] != null 
                                    ? (widget.existingPersonnel!['image'].startsWith('assets/')
                                        ? Image.asset(widget.existingPersonnel!['image'], fit: BoxFit.cover)
                                        : (kIsWeb 
                                            ? Image.network(widget.existingPersonnel!['image'], fit: BoxFit.cover)
                                            : Image.file(File(widget.existingPersonnel!['image']), fit: BoxFit.cover)))
                                    : Container(
                                        color: DashboardTheme.surfaceSecondary,
                                        child: Icon(Icons.add_a_photo_rounded, color: DashboardTheme.primary.withOpacity(0.5), size: 40),
                                      )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: DashboardTheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded, color: Colors.black, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Personnel Type
            Text("ประเภทบุคลากร", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeChip("technician", "ช่างซ่อม", Icons.engineering_rounded),
                const SizedBox(width: 12),
                _typeChip("legal", "นิติกรหมู่บ้าน", Icons.admin_panel_settings_rounded),
              ],
            ),
            const SizedBox(height: 28),

            // Form Fields
            _labeledField("ชื่อ-นามสกุล", _nameController),
            const SizedBox(height: 20),
            _labeledField("หมายเลขบัตรประชาชน (13 หลัก)", _idCardController, maxLength: 13, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _labeledField("เบอร์โทรศัพท์", _phoneController, maxLength: 10, keyboardType: TextInputType.phone)),
                const SizedBox(width: 20),
                Expanded(child: _labeledField("LINE ID", _lineController, isOptional: true)),
              ],
            ),
            const SizedBox(height: 20),
            _labeledField("อีเมล (E-Mail)", _emailController, isOptional: true, keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 40),
            Text("PERSONAL PROFILE // ข้อมูลส่วนตัวเสริม", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(child: _labeledField("อายุ", _ageController, keyboardType: TextInputType.number)),
                const SizedBox(width: 20),
                Expanded(child: _labeledField("ส่วนสูง (เช่น 175 cm)", _heightController)),
              ],
            ),
            const SizedBox(height: 20),
            _labeledField("สถานที่เกิด (Birthplace)", _birthplaceController),
            const SizedBox(height: 20),
            _labeledField("ประวัติย่อ / ความสามารถที่โดดเด่น", _bioController, isOptional: true, maxLines: 3, keyboardType: TextInputType.multiline),

            const SizedBox(height: 40),
            Text("SKILL METRICS // ค่าสถิติทักษะ (RADAR CHART)", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _labeledSlider("AIR", _statAir, (val) => setState(() => _statAir = val)),
                      _labeledSlider("POWER", _statPower, (val) => setState(() => _statPower = val)),
                      _labeledSlider("PIPE", _statPipe, (val) => setState(() => _statPipe = val)),
                      _labeledSlider("BUILD", _statBuild, (val) => setState(() => _statBuild = val)),
                      _labeledSlider("PAINT", _statPaint, (val) => setState(() => _statPaint = val)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DashboardTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DashboardTheme.border),
                    ),
                    child: CustomPaint(
                      painter: RadarChartPainter(
                        stats: {
                          'AIR': _statAir,
                          'POWER': _statPower,
                          'PIPE': _statPipe,
                          'BUILD': _statBuild,
                          'PAINT': _statPaint,
                        },
                        color: DashboardTheme.primary,
                        labelColor: DashboardTheme.textPale.withOpacity(0.5),
                        gridColor: DashboardTheme.border.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Error Message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: DashboardTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: DashboardTheme.error.withOpacity(0.3))),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: DashboardTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: GoogleFonts.notoSans(color: DashboardTheme.error, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onDismiss,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _validate,
                    style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.primary, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                    child: Text("ไปยังขั้นตอนถัดไป", style: GoogleFonts.notoSans(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledSlider(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 11, fontWeight: FontWeight.bold)),
              Text("${(value * 100).toInt()}%", style: GoogleFonts.shareTechMono(color: DashboardTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DashboardTheme.primary,
              inactiveTrackColor: DashboardTheme.border,
              thumbColor: DashboardTheme.primary,
              overlayColor: DashboardTheme.primary.withOpacity(0.1),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardPreview() {
    return Container(
      key: const ValueKey('preview'),
      width: 500,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: DashboardTheme.primary.withOpacity(0.1), blurRadius: 40, spreadRadius: 4),
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 60),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text("ELECTRONIC ID CARD", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
          Text("บัตรประจำตัวพนักงานอิเล็กทรอนิกส์", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 10)),
          const SizedBox(height: 28),

          // ID Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DashboardTheme.surfaceSecondary,
                  DashboardTheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DashboardTheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                // Photo + Info
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: DashboardTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DashboardTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _pickedFile != null
                            ? (kIsWeb 
                                ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                                : Image.file(File(_pickedFile!.path), fit: BoxFit.cover))
                            : Icon(Icons.person_rounded, color: DashboardTheme.textPale, size: 40),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_nameController.text, style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(_selectedType == 'technician' ? 'ช่างซ่อม' : 'นิติกรหมู่บ้าน', style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _idRow("ID", _generatedEmployeeId ?? ''),
                          _idRow("TEL", _phoneController.text),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: DashboardTheme.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("VIVORN VILLA FACILITY", style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale, fontSize: 9, letterSpacing: 1)),
                    Text("ACTIVE ●", style: GoogleFonts.notoSans(color: const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text("รหัสผ่านเริ่มต้น = หมายเลขบัตรประชาชน", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 10)),
          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _showIdCard = false),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: Text("ย้อนกลับ", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text("บันทึก", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? DashboardTheme.primary.withOpacity(0.1) : DashboardTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? DashboardTheme.primary : DashboardTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? DashboardTheme.primary : DashboardTheme.textPale, size: 18),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.notoSans(color: isSelected ? DashboardTheme.primary : DashboardTheme.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController controller, {int? maxLength, TextInputType? keyboardType, bool isOptional = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 11, fontWeight: FontWeight.bold)),
            if (isOptional) Text(" (optional)", style: GoogleFonts.notoSans(color: DashboardTheme.textPale.withOpacity(0.5), fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: DashboardTheme.surfaceSecondary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _idRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(label, style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: GoogleFonts.shareTechMono(color: DashboardTheme.textMain, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
