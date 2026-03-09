import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class ResidentRepairView extends StatefulWidget {
  final bool isDark;

  const ResidentRepairView({
    super.key,
    required this.isDark,
  });

  @override
  State<ResidentRepairView> createState() => _ResidentRepairViewState();
}

class _ResidentRepairViewState extends State<ResidentRepairView> {
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  String _selectedCategory = '';
  bool _isUrgent = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSlot; // SRS: 'AM' or 'PM'
  RepairRequest? _expandedTicket;
  List<String> _attachedImages = []; // List of attached image paths
  bool _showConfirmation = false;
  final ImagePicker _picker = ImagePicker();

  final _categories = [
    {'group': 'Bathroom', 'items': ['Bathtub', 'Toilet', 'Water Heater']},
    {'group': 'Kitchen', 'items': ['Refrigerator', 'Oven', 'Dishwasher']},
    {'group': 'Living Room', 'items': ['Air Conditioner', 'TV/Display']},
    {'group': 'Infrastructure', 'items': ['Doors/Windows', 'Lighting', 'Plumbing']},
  ];

  // SRS V2.0: Warranty & Cost Logic
  final DateTime _transferDate = DateTime(2022, 10, 10); // Example Transfer/Handover Date
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  bool _checkWarranty() {
    final expiryDate = DateTime(_transferDate.year + 5, _transferDate.month, _transferDate.day);
    return DateTime.now().isBefore(expiryDate);
  }

  double _calculateCost() {
    if (_checkWarranty()) return 0.0;
    // Base service charge for out-of-warranty
    return 1500.0; 
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // SRS: Business hours validation
  bool _isValidTime(TimeOfDay time) {
    final double minutes = time.hour * 60.0 + time.minute;
    // AM: 09:30 - 12:00
    final bool isAM = minutes >= (9 * 60 + 30) && minutes <= (12 * 60);
    // PM: 13:00 - 16:00
    final bool isPM = minutes >= (13 * 60) && minutes <= (16 * 60);
    return isAM || isPM;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 30),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );

    if (picked != null) {
      if (_isValidTime(picked)) {
        setState(() {
          _selectedTime = picked;
          // Sync with slot for backend/repo compatibility
          _selectedSlot = (picked.hour < 12) ? 'AM' : 'PM';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณาเลือกเวลาในช่วง 09:30-12:00 หรือ 13:00-16:00'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _attachedImages.addAll(images.map((img) => img.path));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Widget _buildPickerTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.dark(
          primary: DashboardTheme.primary,
          onPrimary: Colors.black,
          surface: const Color(0xFF16161C),
          onSurface: Colors.white,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = DashboardTheme.primary;
    final primaryGlow = DashboardTheme.primary;

    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, _) {
        return Material(
          color: DashboardTheme.background,
          child: Stack(
            children: [
              Positioned.fill(child: Opacity(opacity: 0.015, child: CustomPaint(painter: _GridPainter(color: primaryGlow)))),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Form Area
                    Expanded(
                      flex: 13,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 60),
                            _buildForm(glowColor),
                            const SizedBox(height: 120), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 80),
                    // Sidebar Area (History)
                    Expanded(
                      flex: 6,
                      child: _buildHistoryPanel(glowColor),
                    ),
                  ],
                ),
              ),
    
              if (_showConfirmation) _buildConfirmationOverlay(primaryGlow),
              if (_expandedTicket != null) _buildDetailOverlay(primaryGlow),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Console', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: DashboardTheme.textMain, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Submit and track your maintenance requests with high-end precision.', style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textPale)),
      ],
    );
  }

  Widget _buildForm(Color gold) {
    final glowColor = _isUrgent ? Colors.redAccent.shade200 : gold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Category', glowColor),
        const SizedBox(height: 12),
        _PremiumDropdown(selected: _selectedCategory, items: _categories, onChanged: (v) => setState(() => _selectedCategory = v)),
        const SizedBox(height: 36),
        
        _buildLabel('Subject', glowColor),
        const SizedBox(height: 12),
        _PremiumInput(controller: _titleCtrl, hint: 'e.g. Broken AC, Water leak...', activeColor: glowColor),
        const SizedBox(height: 36),

        _buildLabel('Details', glowColor), 
        const SizedBox(height: 12),
        _PremiumInput(controller: _detailCtrl, hint: 'Describe the issue in detail...', activeColor: glowColor, maxLines: 4),
        const SizedBox(height: 36),
        
        _buildLabel('Appointment Schedule', glowColor),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ScheduleTrigger(label: 'Pick Date', value: _selectedDate == null ? null : DateFormat('MMM dd, yyyy').format(_selectedDate!), icon: Icons.calendar_month_rounded, onTap: _pickDate, activeColor: glowColor)),
            const SizedBox(width: 16),
            Expanded(child: _ScheduleTrigger(label: 'Pick Time', value: _selectedTime?.format(context), icon: Icons.access_time_filled_rounded, onTap: _pickTime, activeColor: glowColor)),
          ],
        ),
        const SizedBox(height: 36),
        
        _buildLabel('Support Documents (Photos)', glowColor),
        const SizedBox(height: 12),
        _PhotoPicker(imagePaths: _attachedImages, onTap: _pickImages, onRemove: _removeImage, activeColor: glowColor),
        const SizedBox(height: 48),
        
        _EmergencyToggle(value: _isUrgent, onChanged: (v) => setState(() => _isUrgent = v)),
        const SizedBox(height: 56),
        
        _SubmitAction(onTap: () => setState(() => _showConfirmation = true), isUrgent: _isUrgent, gold: gold),
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2, color: color.withOpacity(0.4)));
  }

  Widget _buildConfirmationOverlay(Color gold) {
    final timeStr = _selectedTime?.format(context) ?? 'Not set';
    final dateStr = _selectedDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(_selectedDate!);

    return Positioned.fill(
      child: Container(
        color: (DashboardTheme.isDarkMode.value ? Colors.black : const Color(0xFFFDFBF7)).withOpacity(0.92),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _TactileSlab(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Final Review', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
                          const SizedBox(height: 32),
                          _ReviewRow(label: 'Topic', value: _selectedCategory),
                          _ReviewRow(label: 'Subject', value: _titleCtrl.text),
                          _ReviewRow(label: 'Schedule', value: "$dateStr at $timeStr"),
                          _ReviewRow(label: 'Urgency', value: _isUrgent ? 'EMERGENCY' : 'Regular', isRed: _isUrgent),
                          Divider(color: DashboardTheme.border, height: 48),
                          _ReviewRow(
                            label: 'Warranty', 
                            value: _checkWarranty() ? '5-Year Shield Active' : 'Warranty Expired', 
                            isGreen: _checkWarranty(),
                            isRed: !_checkWarranty(),
                          ),
                          _ReviewRow(
                            label: 'Coverage Info', 
                            value: 'Expires: ${DateFormat('MMM dd, yyyy').format(DateTime(_transferDate.year + 5, _transferDate.month, _transferDate.day))}',
                          ),
                          _ReviewRow(label: 'Est. Cost', value: '฿${_calculateCost().toStringAsFixed(2)}', isBold: true),
                          const SizedBox(height: 54),
                          Row(
                            children: [
                              Expanded(child: _OverlayBtn(label: 'Confirm Submit', color: gold, onTap: _executeSubmission)),
                              const SizedBox(width: 16),
                              Expanded(child: _OverlayBtn(label: 'Cancel', color: DashboardTheme.textMain.withOpacity(0.05), isOutline: true, onTap: () => setState(() => _showConfirmation = false))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_attachedImages.isNotEmpty) ...[
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Evidence Gallery (${_attachedImages.length})', style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale.withOpacity(0.5), fontSize: 13, letterSpacing: 2)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 400,
                              child: ListView.separated(
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemCount: _attachedImages.length,
                                itemBuilder: (context, idx) => _PhotoPreview(path: _attachedImages[idx]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _executeSubmission() {
    RepairRepository.instance.addRequest(
      title: _titleCtrl.text,
      description: _detailCtrl.text,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTime,
      appointmentSlot: _selectedSlot,
      isEmergency: _isUrgent,
      isWarranty: _checkWarranty(),
      estimatedCost: _calculateCost(),
      imagePaths: _attachedImages,
    );
    
    _titleCtrl.clear();
    _detailCtrl.clear();
    _selectedCategory = '';
    _selectedDate = null;
    _selectedTime = null;
    _selectedSlot = null;
    _isUrgent = false;
    _attachedImages = [];
    _showConfirmation = false;
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request logged in core registry.'), backgroundColor: Colors.green));
  }

  Widget _buildHistoryPanel(Color gold) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registry History', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
        const SizedBox(height: 4),
        Text('Reviewing your past and active logs.', style: GoogleFonts.outfit(fontSize: 14, color: DashboardTheme.textPale)),
        const SizedBox(height: 40),
        Expanded(
          child: ValueListenableBuilder<List<RepairRequest>>(
            valueListenable: RepairRepository.instance.repairsNotifier,
            builder: (context, repairs, _) {
              if (repairs.isEmpty) return _buildNoData();
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: repairs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _HistoryCard(item: repairs[index], onTap: () => setState(() => _expandedTicket = repairs[index])),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoData() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.query_builder_rounded, size: 40, color: DashboardTheme.textPale.withOpacity(0.1)), const SizedBox(height: 16), Text('Records Empty', style: GoogleFonts.outfit(color: DashboardTheme.textPale))]));
  }

  Widget _buildDetailOverlay(Color gold) {
    final t = _expandedTicket!;
    final dateStr = t.appointmentDate != null ? DateFormat('MMM dd, yyyy').format(t.appointmentDate!) : 'N/A';
    final timeStr = t.appointmentTime?.format(context) ?? 'N/A';

    return Positioned.fill(
      child: Container(
        color: (DashboardTheme.isDarkMode.value ? Colors.black : const Color(0xFFFDFBF7)).withOpacity(0.95),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _TactileSlab(
              child: Padding(
                padding: const EdgeInsets.all(54),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusBadge(status: t.status, color: t.statusColor),
                              // REMOVED Redundant X IconButton for V17 Standardization
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(t.title, style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.bold, color: DashboardTheme.textMain)),
                          const SizedBox(height: 12),
                          Text(t.description, style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textSecondary)),
                          const SizedBox(height: 24),
                          Text('Technician Lead: ${t.technicianName ?? "Awaiting Assignment"}', style: GoogleFonts.outfit(fontSize: 15, color: DashboardTheme.textPale)),
                          Divider(color: DashboardTheme.border, height: 48),
                          _ReviewRow(label: 'Registry Code', value: t.id),
                          _ReviewRow(label: 'Appointment', value: "$dateStr @ $timeStr"),
                          _ReviewRow(label: 'Warranty Shield', value: t.isWarranty ? 'ACTIVE' : 'EXPIRED', isGreen: t.isWarranty),
                          const SizedBox(height: 48),
                          if (t.status == 'Pending') ...[
                            _OverlayBtn(
                              label: 'Cancel Request', 
                              color: Colors.redAccent.withOpacity(0.8), 
                              onTap: () {
                                _showCancelConfirmation(context, t.id);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          _OverlayBtn(label: 'Close', color: DashboardTheme.textMain.withOpacity(0.1), isOutline: true, onTap: () => setState(() => _expandedTicket = null)),
                        ],
                      ),
                    ),
                    if (t.imagePaths.isNotEmpty) ...[
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ATTACHED EVIDENCE', style: GoogleFonts.shareTechMono(color: Colors.white30, fontSize: 13, letterSpacing: 2)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 500,
                              child: ListView.separated(
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemCount: t.imagePaths.length,
                                itemBuilder: (context, idx) => _PhotoPreview(path: t.imagePaths[idx]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _showCancelConfirmation(BuildContext context, String id) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: Colors.transparent,
              child: _TactileSlab(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Confirm Cancellation?', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      Text('This action will permanently remove the request from the registry history.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white60)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _OverlayBtn(
                              label: 'Confirm', 
                              color: Colors.redAccent.withOpacity(0.7), 
                              onTap: () {
                                RepairRepository.instance.deleteRequest(id);
                                Navigator.pop(context);
                                setState(() => _expandedTicket = null);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request successfully removed.'), backgroundColor: Colors.redAccent));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OverlayBtn(
                              label: 'Go Back', 
                              color: Colors.white.withOpacity(0.05), 
                              isOutline: true, 
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: ScaleTransition(scale: anim1, child: child));
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// V13 FUNCTIONAL COMPONENTS
// ════════════════════════════════════════════════════════════════════

class _TactileSlab extends StatelessWidget {
  final Widget child;
  final double? width;
  final bool isRecessed;
  const _TactileSlab({required this.child, this.width, this.isRecessed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTheme.border.withOpacity(0.2)),
        boxShadow: [
          if (!isRecessed) BoxShadow(color: Colors.black.withOpacity(DashboardTheme.isDarkMode.value ? 0.5 : 0.05), blurRadius: 40, offset: const Offset(0, 20)),
          BoxShadow(color: DashboardTheme.textMain.withOpacity(0.05), blurRadius: 0, spreadRadius: -1, offset: const Offset(-1, -1)),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(top: 15, left: 15, child: _Screw()), const Positioned(top: 15, right: 15, child: _Screw()), const Positioned(bottom: 15, left: 15, child: _Screw()), const Positioned(bottom: 15, right: 15, child: _Screw()),
          child,
        ],
      ),
    );
  }
}

class _Screw extends StatelessWidget {
  const _Screw();
  @override
  Widget build(BuildContext context) { return Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10)); }
}

class _ScheduleTrigger extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final Color activeColor;
  const _ScheduleTrigger({required this.label, this.value, required this.icon, required this.onTap, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasVal ? activeColor.withOpacity(DashboardTheme.isDarkMode.value ? 0.15 : 0.1) : DashboardTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasVal ? activeColor : (DashboardTheme.isDarkMode.value ? DashboardTheme.border.withOpacity(0.2) : DashboardTheme.border.withOpacity(0.5))),
        ),
        child: Column(
          children: [
            Icon(icon, color: hasVal ? activeColor : DashboardTheme.textPale.withOpacity(0.2), size: 28),
            const SizedBox(height: 12),
            Text(label.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 11, color: DashboardTheme.textPale.withOpacity(0.5), letterSpacing: 1)),
            Text(value ?? 'Not Set', style: GoogleFonts.outfit(fontSize: 15, color: hasVal ? DashboardTheme.textMain : DashboardTheme.textPale.withOpacity(0.3), fontWeight: hasVal ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> imagePaths;
  final VoidCallback onTap;
  final Function(int) onRemove;
  final Color activeColor;
  const _PhotoPicker({required this.imagePaths, required this.onTap, required this.onRemove, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final hasPhotos = imagePaths.isNotEmpty;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: hasPhotos ? activeColor.withOpacity(0.5) : DashboardTheme.border)),
            child: Row(
              children: [
                Container(width: 60, height: 60, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: DashboardTheme.surfaceSecondary, borderRadius: BorderRadius.circular(8)), child: Icon(hasPhotos ? Icons.add_photo_alternate_rounded : Icons.camera_alt_rounded, color: hasPhotos ? activeColor : DashboardTheme.textPale)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hasPhotos ? 'ADD MORE PHOTOS' : 'ATTACH PHOTOS', style: GoogleFonts.shareTechMono(fontSize: 13, color: hasPhotos ? activeColor : DashboardTheme.textPale.withOpacity(0.5), fontWeight: FontWeight.bold)),
                  Text('${imagePaths.length} documents selected.', style: GoogleFonts.outfit(fontSize: 12, color: DashboardTheme.textPale)),
                ])),
              ],
            ),
          ),
        ),
        if (hasPhotos) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) => Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 100, height: 100, child: _PhotoPreview(path: imagePaths[idx], isMini: true))),
                  Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => onRemove(idx), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                ],
              ),
            ),
          ),
        ]
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final String path;
  final bool isMini;
  const _PhotoPreview({required this.path, this.isMini = false});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white10));
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white10));
    }
  }
}

class _PremiumInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color activeColor;
  final int maxLines;
  const _PremiumInput({required this.controller, required this.hint, required this.activeColor, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DashboardTheme.border)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextField(controller: controller, maxLines: maxLines, style: GoogleFonts.outfit(fontSize: 17, color: DashboardTheme.textMain), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textPale), border: InputBorder.none)),
    );
  }
}

class _PremiumDropdown extends StatelessWidget {
  final String selected;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onChanged;
  const _PremiumDropdown({required this.selected, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: DashboardTheme.border)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selected.isEmpty ? null : selected, isExpanded: true, dropdownColor: DashboardTheme.surface, icon: Icon(Icons.keyboard_arrow_down_rounded, color: DashboardTheme.textPale), hint: Text('Select Category', style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textPale)),
          items: items.expand((cat) { final g = cat['group'] as String; return (cat['items'] as List<String>).map((i) => DropdownMenuItem(value: '$g: $i', child: Text(i, style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textSecondary)))); }).toList(),
          onChanged: (v) => onChanged(v ?? ''),
        )),
    );
  }
}

class _EmergencyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _EmergencyToggle({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = value ? Colors.redAccent : DashboardTheme.border;
    return GestureDetector(onTap: () => onChanged(!value), child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20), decoration: BoxDecoration(color: value ? Colors.redAccent.withOpacity(0.05) : DashboardTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c)),
        child: Row(children: [Icon(Icons.warning_amber_rounded, color: value ? Colors.redAccent : DashboardTheme.textPale.withOpacity(0.2), size: 30), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('URGENT DISPATCH', style: GoogleFonts.shareTechMono(fontSize: 16, fontWeight: FontWeight.bold, color: value ? Colors.redAccent : DashboardTheme.textPale.withOpacity(0.5), letterSpacing: 1)), Text('Priority maintenance enabled.', style: GoogleFonts.outfit(fontSize: 12, color: DashboardTheme.textPale.withOpacity(0.4)))])), _Switch(value: value)]),
      ));
  }
}

class _Switch extends StatelessWidget {
  final bool value;
  const _Switch({required this.value});
  @override
  Widget build(BuildContext context) { return Container(width: 48, height: 26, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: value ? Colors.redAccent.withOpacity(0.2) : Colors.black45, borderRadius: BorderRadius.circular(13)), child: AnimatedAlign(duration: const Duration(milliseconds: 200), alignment: value ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10)))); }
}

class _SubmitAction extends StatelessWidget {
  final VoidCallback onTap;
  final bool isUrgent;
  final Color gold;
  const _SubmitAction({required this.onTap, required this.isUrgent, required this.gold});
  @override
  Widget build(BuildContext context) { final c = isUrgent ? Colors.redAccent : gold; return GestureDetector(onTap: onTap, child: Container(height: 76, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))]), alignment: Alignment.center, child: Text(isUrgent ? 'EXECUTE EMERGENCY' : 'SUBMIT DATA', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)))); }
}

class _ReviewRow extends StatelessWidget {
  final String label; final String value; final bool isRed; final bool isGreen; final bool isBold;
  const _ReviewRow({required this.label, required this.value, this.isRed = false, this.isGreen = false, this.isBold = false});
  @override
  Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.outfit(color: DashboardTheme.textPale, fontSize: 16)), Text(value.isEmpty ? 'N/A' : value, style: GoogleFonts.outfit(color: isRed ? Colors.redAccent : (isGreen ? Colors.greenAccent : DashboardTheme.textSecondary), fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 17))])); }
}

class _OverlayBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap; final bool isOutline;
  const _OverlayBtn({required this.label, required this.color, required this.onTap, this.isOutline = false});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(height: 60, decoration: BoxDecoration(color: isOutline ? Colors.transparent : color, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), alignment: Alignment.center, child: Text(label, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: isOutline ? DashboardTheme.textPale : Colors.black)))); }
}

class _StatusBadge extends StatelessWidget {
  final String status; final Color color;
  const _StatusBadge({required this.status, required this.color});
  @override
  Widget build(BuildContext context) { return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))), child: Text(status.toUpperCase(), style: GoogleFonts.shareTechMono(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))); }
}

class _HistoryCard extends StatelessWidget {
  final RepairRequest item; final VoidCallback onTap;
  const _HistoryCard({required this.item, required this.onTap});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: DashboardTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: DashboardTheme.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_StatusBadge(status: item.status, color: item.statusColor), Text(item.date, style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale, fontSize: 11))]), const SizedBox(height: 20), Text(item.title, style: GoogleFonts.outfit(fontSize: 18, color: DashboardTheme.textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)]))); }
}

class _GridPainter extends CustomPainter {
  final Color color; _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) { final p = Paint()..color = color.withOpacity(0.04)..strokeWidth = 0.5; const s = 70.0; for (double i = 0; i < size.width; i += s) canvas.drawLine(Offset(i, 0), Offset(i, size.height), p); for (double i = 0; i < size.height; i += s) canvas.drawLine(Offset(0, i), Offset(size.width, i), p); }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
