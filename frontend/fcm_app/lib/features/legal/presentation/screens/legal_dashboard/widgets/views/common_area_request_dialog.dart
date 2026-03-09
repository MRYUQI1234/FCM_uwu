import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/data/dashboard_data.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/technician_schedule_card.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class CommonAreaRequestDialog extends StatefulWidget {
  final VoidCallback? onDismiss;

  const CommonAreaRequestDialog({super.key, this.onDismiss});

  @override
  State<CommonAreaRequestDialog> createState() => _CommonAreaRequestDialogState();
}

class _CommonAreaRequestDialogState extends State<CommonAreaRequestDialog> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String? _selectedLocation;
  String? _selectedCategory;
  bool _isUrgent = false;
  String? _selectedTechId;
  
  String _selectedZone = "Public Park";
  final Set<String> _selectedTechnicians = {}; // Multi-selection
  final List<XFile> _attachedFiles = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedFiles.add(image);
      });
    }
  }

  final List<String> _zones = [
    "Public Park",
    "Club House / Gym",
    "Swimming Pool",
    "Main Gate / Entrance",
    "Facility Electric",
    "Juristic Office"
  ];

  @override
  Widget build(BuildContext context) {
    final technicians = DashboardData.technicians;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: GestureDetector(
                onTap: widget.onDismiss ?? () => Navigator.pop(context),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
          ),
          Positioned(
            top: 60,
            bottom: 270,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 700,
                constraints: const BoxConstraints(maxHeight: double.infinity),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: DashboardTheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: DashboardTheme.border, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
                child: SingleChildScrollView(
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
                                "COMMON AREA MAINTENANCE",
                                style: GoogleFonts.outfit(color: DashboardTheme.textMain, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              terminalText("SERVICE_REQUEST // INTERNAL_PROTOCOL", fontSize: 9, color: DashboardTheme.primary.withOpacity(0.4), letterSpacing: 2, fontWeight: FontWeight.w300),
                            ],
                          ),
                          Material(
                            color: DashboardTheme.surface,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: DashboardTheme.textMain.withOpacity(0.5), size: 24),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 1. LOCATION & CATEGORY ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                terminalText("LOCATION_ID", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DashboardTheme.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: DashboardTheme.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedLocation,
                                      isExpanded: true,
                                      dropdownColor: DashboardTheme.surfaceSecondary,
                                      hint: Text("Select Location", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13)),
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: DashboardTheme.primary),
                                      style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 13, fontWeight: FontWeight.bold),
                                      items: ["LOBBY_MAIN", "GYM_FACILITY", "POOL_DECK", "GARDEN_AREA", "B1_PARKING", "ROOFTOP_LOUNGE"]
                                          .map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                                      onChanged: (val) => setState(() => _selectedLocation = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                terminalText("ISSUE_CATEGORY", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: ["LIGHTING", "HVAC", "CLEANING", "SECURITY", "PLUMBING"].map((cat) {
                                      final isSelected = _selectedCategory == cat;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(cat, style: GoogleFonts.notoSans(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                          selected: isSelected,
                                          onSelected: (val) => setState(() => _selectedCategory = val ? cat : null),
                                          backgroundColor: DashboardTheme.surfaceSecondary,
                                          selectedColor: DashboardTheme.primary.withOpacity(0.2),
                                          labelStyle: TextStyle(color: isSelected ? DashboardTheme.primary : DashboardTheme.textSecondary),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: isSelected ? DashboardTheme.primary.withOpacity(0.5) : Colors.transparent),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. DESCRIPTION & ATTACHMENT
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                terminalText("ISSUE_DESCRIPTION", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: DashboardTheme.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: DashboardTheme.border),
                                  ),
                                  child: TextField(
                                    controller: _descController,
                                    maxLines: 4,
                                    style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: "Describe the issue in detail...",
                                      hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13),
                                      contentPadding: const EdgeInsets.all(16),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                terminalText("EVIDENCE", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1),
                                const SizedBox(height: 12),
                                Container(
                                  height: 115,
                                  decoration: BoxDecoration(
                                    color: DashboardTheme.surfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: DashboardTheme.border, style: BorderStyle.solid), // Dashed border usually better but solid matches style
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_rounded, color: DashboardTheme.primary, size: 24),
                                        const SizedBox(height: 8),
                                        Text("ADD", style: TextStyle(color: DashboardTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. PRIORITY TOGGLE
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isUrgent ? DashboardTheme.error.withOpacity(0.1) : DashboardTheme.surfaceSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isUrgent ? DashboardTheme.error.withOpacity(0.5) : DashboardTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: _isUrgent ? DashboardTheme.error : DashboardTheme.textPale),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("HIGH PRIORITY PROTOCOL", style: GoogleFonts.notoSans(color: _isUrgent ? DashboardTheme.error : DashboardTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text("Flag this issue for immediate attention", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 10)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isUrgent,
                                    onChanged: (val) => setState(() => _isUrgent = val),
                                    activeColor: DashboardTheme.error,
                                    activeTrackColor: DashboardTheme.error.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                       const SizedBox(height: 24),

                      // 4. TECHNICIAN ASSIGNMENT (OPTIONAL)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          terminalText("ASSIGN_TECHNICIAN (OPTIONAL)", fontSize: 10, color: DashboardTheme.textPale, letterSpacing: 1),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: DashboardData.technicians.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final tech = DashboardData.technicians[index];
                                final isSelected = _selectedTechId == tech['id'];
                                final bool isActive = tech['isActive'] as bool? ?? true; // Check active status

                                return GestureDetector(
                                  onTap: isActive ? () => setState(() {
                                    if (isSelected) {
                                      _selectedTechId = null;
                                    } else {
                                      _selectedTechId = tech['id'];
                                    }
                                  }) : null,
                                  child: Opacity(
                                    opacity: isActive ? 1.0 : 0.4,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? DashboardTheme.primary.withOpacity(0.08) : DashboardTheme.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                            ? DashboardTheme.primary
                                            : Colors.transparent,
                                          width: 1.5,
                                        ),
                                        boxShadow: isSelected ? [
                                          BoxShadow(color: DashboardTheme.primary.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
                                        ] : [],
                                      ),
                                      child: Row(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 32, height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: (isActive ? DashboardTheme.primary : DashboardTheme.textPale).withOpacity(0.5)),
                                                  image: DecorationImage(image: AssetImage(tech['image']), fit: BoxFit.cover),
                                                ),
                                              ),
                                              if (!isActive)
                                                Container(
                                                  width: 32, height: 32,
                                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                                  child: Icon(Icons.block, color: DashboardTheme.textPale, size: 16),
                                                ),
                                            ],
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 12),
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(tech['name'], style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontWeight: FontWeight.bold, fontSize: 12)),
                                                Row(
                                                  children: [
                                                    Icon(tech['icon'], color: isActive ? DashboardTheme.primary : DashboardTheme.textPale, size: 10),
                                                    const SizedBox(width: 4),
                                                    terminalText(tech['role'].toString().split(' ').last, fontSize: 8, color: DashboardTheme.textPale),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: DashboardTheme.surface,
                                                border: Border.all(color: DashboardTheme.primary, width: 2),
                                              ),
                                              child: Icon(Icons.check_circle, color: DashboardTheme.primary, size: 16),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 5. FOOTER ACTIONS
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text("CANCEL_PROTOCOL", style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                // Add logic to submit mock task
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 12),
                                  Text("SUBMIT REQUEST", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                                ],
                              ),
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
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return terminalText(label, fontSize: 10, color: DashboardTheme.textPale, fontWeight: FontWeight.bold, letterSpacing: 1);
  }

  Widget _buildTextField({required TextEditingController controller, String hint = "", int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 14),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DashboardTheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
