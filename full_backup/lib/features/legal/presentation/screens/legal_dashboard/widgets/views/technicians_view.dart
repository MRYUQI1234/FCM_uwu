import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_ui_utils.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_painters.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/personnel_dossier_overlay.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/add_personnel_overlay.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class TechniciansView extends StatefulWidget {
  final List<Map<String, dynamic>> technicians;

  const TechniciansView({
    super.key,
    required this.technicians,
  });

  @override
  State<TechniciansView> createState() => _TechniciansViewState();
}

enum RegistryTab { staffs, teams }

class _TechniciansViewState extends State<TechniciansView> {
  bool _showAddOverlay = false;
  Map<String, dynamic>? _editTarget;
  // Registry Navigation
  RegistryTab _activeTab = RegistryTab.staffs;
  TeamPreset? _selectedTeamPreset;
  // Team creation mode
  bool _isCreatingTeam = false;
  List<String> _teamDraftMembers = [];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Stack(
          children: [
            Container(
              color: DashboardTheme.background,
              padding: const EdgeInsets.fromLTRB(28, 90, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER TOP ROW (Title & Actions) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          terminalText("SYS.ADMIN // PERSONNEL REGISTRY", fontSize: 10, color: DashboardTheme.primary.withOpacity(0.5), letterSpacing: 1.5),
                          const SizedBox(height: 12),
                          Text(
                            _activeTab == RegistryTab.staffs ? "Personnel Registry" : "Teams Registry",
                            style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 32, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // ── ADD PERSONNEL BUTTON (RIGHT TOP) ──
                          if (!_isCreatingTeam && _activeTab == RegistryTab.staffs)
                            ElevatedButton.icon(
                              onPressed: () => setState(() {
                                _editTarget = null;
                                _showAddOverlay = true;
                              }),
                              icon: const Icon(Icons.person_add_rounded, size: 18),
                              label: Text("เพิ่มบุคลากร", style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DashboardTheme.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          // ── CREATE TEAM BUTTON (RIGHT TOP) ──
                          if (!_isCreatingTeam && _activeTab == RegistryTab.teams)
                            ElevatedButton.icon(
                              onPressed: () => setState(() {
                                _isCreatingTeam = true;
                                _teamDraftMembers = [];
                              }),
                              icon: const Icon(Icons.group_add_rounded, size: 18),
                              label: Text("สร้างทีม", style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── TAB SWITCHER BAR (ALIGNED LEFT TO MATCH REQUESTS) ──
                  if (!_isCreatingTeam)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: DashboardTheme.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: DashboardTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<List<TeamPreset>>(
                                valueListenable: RepairRepository.instance.teamPresetsNotifier,
                                builder: (context, presets, _) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModernTab("บุคลากร", "${widget.technicians.length}", _activeTab == RegistryTab.staffs, () => setState(() { 
                                        _activeTab = RegistryTab.staffs; 
                                        _selectedTeamPreset = null;
                                      })),
                                      _buildModernTab("ทีม", "${presets.length}", _activeTab == RegistryTab.teams, () => setState(() { 
                                        _activeTab = RegistryTab.teams; 
                                        _selectedTeamPreset = null;
                                      })),
                                    ],
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                        const Spacer(), // PUSH TO LEFT
                      ],
                    ),
                  const SizedBox(height: 24),

                  // ── TEAM CREATION BAR (visible when creating) ──
                  if (_isCreatingTeam)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E676), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "เลือกสมาชิกทีม (${_teamDraftMembers.length} คน)",
                            style: GoogleFonts.notoSans(color: Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              _isCreatingTeam = false;
                              _teamDraftMembers = [];
                            }),
                            child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _teamDraftMembers.isEmpty ? null : () => _showSaveTeamDialog(),
                            icon: const Icon(Icons.folder_special_rounded, size: 16),
                            label: Text("บันทึกเป็น Preset", style: GoogleFonts.notoSans(fontWeight: FontWeight.w800, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                              disabledForegroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── DYNAMIC VIEW BODY ──
                  if (_activeTab == RegistryTab.teams && _selectedTeamPreset == null && !_isCreatingTeam)
                    Expanded(
                      child: ValueListenableBuilder<List<TeamPreset>>(
                        valueListenable: RepairRepository.instance.teamPresetsNotifier,
                        builder: (context, presets, _) {
                          if (presets.isEmpty) return Center(child: Text("ยังไม่มีข้อมูลทีม", style: GoogleFonts.notoSans(color: DashboardTheme.textPale)));
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            itemCount: (presets.length / 3).ceil(),
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, rowIndex) {
                              return Row(
                                children: List.generate(3, (colIndex) {
                                  final index = rowIndex * 3 + colIndex;
                                  if (index >= presets.length) return const Expanded(child: SizedBox());
                                  final preset = presets[index];
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: colIndex == 2 ? 0 : 16),
                                      child: _buildRegistryTeamCard(preset),
                                    ),
                                  );
                                }),
                              );
                            },
                          );
                        },
                      ),
                    )
                  else ...[
                    // Back logic if team selected
                    if (_activeTab == RegistryTab.teams && _selectedTeamPreset != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => setState(() => _selectedTeamPreset = null),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new_rounded, color: DashboardTheme.primary, size: 14),
                                const SizedBox(width: 8),
                                Text(" กลับไปที่หน้ารายชื่อทีม", style: GoogleFonts.notoSans(color: DashboardTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                  // ── TABLE HEADER ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: DashboardTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DashboardTheme.border),
                    ),
                    child: Row(
                      children: [
                        if (_isCreatingTeam) _staffHeaderCell("", flex: 1),
                        _staffHeaderCell("Photo", flex: 1),
                        _staffHeaderCell("Member name", flex: 3),
                        _staffHeaderCell("Mobile", flex: 2),
                        _staffHeaderCell("Email", flex: 3),
                        _staffHeaderCell("Status", flex: 2),
                        _staffHeaderCell("Job", flex: 2),
                        _staffHeaderCell("Rating", flex: 2),
                        if (!_isCreatingTeam) _staffHeaderCell("", flex: 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── TABLE BODY ──
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: _getDisplayPersonnel().length,
                        separatorBuilder: (_, __) => Divider(color: DashboardTheme.border, height: 1),
                        itemBuilder: (context, index) => _buildStaffRow(context, _getDisplayPersonnel()[index]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── ADD / EDIT OVERLAY ──
            if (_showAddOverlay)
              Positioned.fill(
                child: AddPersonnelOverlay(
                  existingPersonnel: _editTarget,
                  onDismiss: () => setState(() {
                    _showAddOverlay = false;
                    _editTarget = null;
                  }),
                  onSave: (data) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _editTarget != null
                            ? "แก้ไขข้อมูลบุคลากรเรียบร้อยแล้ว"
                            : "เพิ่มบุคลากรใหม่เรียบร้อยแล้ว &mdash; รหัสพนักงาน: ${data['id']}",
                          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: DashboardTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    setState(() {
                      _showAddOverlay = false;
                      _editTarget = null;
                    });
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildModernTab(String label, String count, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? DashboardTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? DashboardTheme.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: isActive ? DashboardTheme.primary : DashboardTheme.textPale,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? DashboardTheme.primary : DashboardTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count,
                style: GoogleFonts.shareTechMono(
                  color: isActive ? Colors.black : DashboardTheme.textPale,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDisplayPersonnel() {
    if (_isCreatingTeam || _activeTab == RegistryTab.staffs) {
      return widget.technicians;
    } else {
      if (_selectedTeamPreset == null) return [];
      return widget.technicians.where((t) => _selectedTeamPreset!.memberNames.contains(t['name'])).toList();
    }
  }

  // ── REGISTRY TEAM CARD ──
  Widget _buildRegistryTeamCard(TeamPreset preset) {
    return InkWell(
      onTap: () => setState(() => _selectedTeamPreset = preset),
      onLongPress: () => _showDeletePresetDialog(preset),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DashboardTheme.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DashboardTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(preset.icon, color: DashboardTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(preset.name, style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 16, fontWeight: FontWeight.w900)),
                      Text("${preset.memberNames.length} Members", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: DashboardTheme.textPale.withOpacity(0.5), size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              children: preset.memberNames.take(3).map((name) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DashboardTheme.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(name, style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 10)),
              )).toList(),
            ),
            if (preset.memberNames.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text("+${preset.memberNames.length - 3} others...", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _staffHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label, style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStaffRow(BuildContext context, Map<String, dynamic> tech) {
    bool isHovered = false;
    bool isActive = tech['isActive'] as bool? ?? true;
    final String techName = tech['name'] as String;
    final bool isTeamSelected = _teamDraftMembers.contains(techName);

    return StatefulBuilder(
      builder: (context, setRowState) {
        return MouseRegion(
          onEnter: (_) => setRowState(() => isHovered = true),
          onExit: (_) => setRowState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: _isCreatingTeam && isActive ? () {
              setState(() {
                if (isTeamSelected) {
                  _teamDraftMembers.remove(techName);
                } else {
                  _teamDraftMembers.add(techName);
                }
              });
            } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isTeamSelected && _isCreatingTeam
                    ? const Color(0xFF00E676).withOpacity(0.08)
                    : (isHovered ? DashboardTheme.primary.withOpacity(0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isTeamSelected && _isCreatingTeam
                    ? Border.all(color: const Color(0xFF00E676).withOpacity(0.3))
                    : null,
              ),
              child: Opacity(
                opacity: isActive ? 1.0 : 0.6,
                child: Row(
                  children: [
                    // Checkbox for team creation
                    if (_isCreatingTeam)
                      Expanded(
                        flex: 1,
                        child: Checkbox(
                          value: isTeamSelected,
                          onChanged: isActive ? (val) {
                            setState(() {
                              if (val == true) {
                                _teamDraftMembers.add(techName);
                              } else {
                                _teamDraftMembers.remove(techName);
                              }
                            });
                          } : null,
                          activeColor: const Color(0xFF00E676),
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 40, height: 40,
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: DashboardTheme.primary.withOpacity(0.1),
                          backgroundImage: (tech['image'] as String).startsWith('assets/')
                              ? AssetImage(tech['image'] as String) as ImageProvider
                              : (kIsWeb 
                                  ? NetworkImage(tech['image'] as String)
                                  : FileImage(File(tech['image'] as String))),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _isCreatingTeam ? null : () => _showTechnicianDossier(context, tech),
                        child: Text(
                          techName,
                          style: GoogleFonts.notoSans(
                            color: isTeamSelected && _isCreatingTeam ? const Color(0xFF00E676) : DashboardTheme.textMain,
                            fontWeight: FontWeight.w600, fontSize: 14,
                            decoration: isHovered && isActive && !_isCreatingTeam ? TextDecoration.underline : TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(tech['phone'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13))),
                    Expanded(flex: 3, child: Text(tech['email'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13))),
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? DashboardTheme.success.withOpacity(0.1) : DashboardTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isActive ? DashboardTheme.success.withOpacity(0.2) : DashboardTheme.error.withOpacity(0.2)),
                          ),
                          child: Text(isActive ? "Active" : "Inactive",
                            style: GoogleFonts.notoSans(color: isActive ? DashboardTheme.success : DashboardTheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ),
                    Expanded(flex: 2, child: Text(tech['role'] as String, style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Icon(Icons.star_rounded, color: DashboardTheme.accentAmber, size: 16),
                        const SizedBox(width: 4),
                        Text("${tech['rating']}", style: GoogleFonts.shareTechMono(color: DashboardTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    // Meatball menu (hidden during team creation)
                    if (!_isCreatingTeam)
                      Expanded(
                        flex: 1,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isHovered ? 1.0 : 0.0,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, color: DashboardTheme.textPale, size: 20),
                            color: DashboardTheme.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                setState(() { _editTarget = tech; _showAddOverlay = true; });
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(context, tech);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Row(children: [
                                Icon(Icons.edit_rounded, color: DashboardTheme.primary, size: 16),
                                const SizedBox(width: 10),
                                Text("แก้ไขข้อมูล", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 13)),
                              ])),
                              PopupMenuItem(value: 'delete', child: Row(children: [
                                Icon(Icons.delete_rounded, color: DashboardTheme.error, size: 16),
                                const SizedBox(width: 10),
                                Text("ลบบุคลากร", style: GoogleFonts.notoSans(color: DashboardTheme.error, fontSize: 13)),
                              ])),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── SAVE TEAM DIALOG ──
  void _showSaveTeamDialog() {
    final nameController = TextEditingController();
    final memberCount = _teamDraftMembers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.folder_special_rounded, color: Color(0xFF00E676), size: 22),
          const SizedBox(width: 10),
          Text("ตั้งชื่อทีม", style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("สมาชิก $memberCount คน: ${_teamDraftMembers.join(', ')}",
                style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.notoSans(color: DashboardTheme.textMain, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "เช่น ทีมไฟฟ้า, ทีมประปา...",
                  hintStyle: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontSize: 13),
                  prefixIcon: Icon(Icons.group_rounded, color: DashboardTheme.primary, size: 20),
                  filled: true,
                  fillColor: DashboardTheme.surfaceSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: DashboardTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E676), width: 1.5)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                RepairRepository.instance.addTeamPreset(
                  name: name,
                  memberNames: List<String>.from(_teamDraftMembers),
                  icon: Icons.folder_rounded,
                );
                Navigator.pop(ctx);
                setState(() { _isCreatingTeam = false; _teamDraftMembers = []; });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('บันทึกทีม "$name" ($memberCount คน) เรียบร้อยแล้ว', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF00E676),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text("บันทึก", style: GoogleFonts.notoSans(fontWeight: FontWeight.w900, fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  // ── DELETE PRESET DIALOG ──
  void _showDeletePresetDialog(TeamPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ลบทีม "${preset.name}" ?', style: GoogleFonts.notoSans(color: DashboardTheme.error, fontSize: 16, fontWeight: FontWeight.w900)),
        content: Text("ทีมนี้มี ${preset.memberNames.length} สมาชิก", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              RepairRepository.instance.deleteTeamPreset(preset.name);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('ลบทีม "${preset.name}" แล้ว', style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                backgroundColor: DashboardTheme.error, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("ลบ", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> tech) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("ยืนยันที่จะลบบุคลากรหรือไม่", style: GoogleFonts.notoSans(color: DashboardTheme.error, fontSize: 16, fontWeight: FontWeight.w900)),
        content: Text("ลบ ${tech['name']} ออกจากระบบ?", style: GoogleFonts.notoSans(color: DashboardTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ยกเลิก", style: GoogleFonts.notoSans(color: DashboardTheme.textPale, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("ลบบุคลากร ${tech['name']} เรียบร้อยแล้ว", style: GoogleFonts.notoSans(fontWeight: FontWeight.w600)),
                backgroundColor: DashboardTheme.error, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: DashboardTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text("ตกลง", style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showTechnicianDossier(BuildContext context, Map<String, dynamic> tech) {
    showDialog(
      context: context,
      builder: (context) => PersonnelDossierOverlay(
        technician: tech,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }
}
