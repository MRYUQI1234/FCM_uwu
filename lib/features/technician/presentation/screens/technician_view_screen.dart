import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/profile_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/views/settings_view.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/hover_sidebar.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/shared/widgets/pin_verification_overlay.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'dart:js' as js;

class TechnicianViewScreen extends StatefulWidget {
  const TechnicianViewScreen({super.key});

  @override
  State<TechnicianViewScreen> createState() => _TechnicianViewScreenState();
}

class _TechnicianViewScreenState extends State<TechnicianViewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _displayName = TranslationService.instance.t('loading');
  String _displayRole = "TECHNICIAN";
  String _displayEmail = "";
  String _displayPhone = "";
  String _displayImage = "assets/resident_profile.png";
  bool _sidebarOpen = false;

  // New state for task management
  String? _selectedTaskFilter = "All";

  RepairRequest? _selectedTask;
  int _selectedCalendarDay = DateTime.now().day;
  final TextEditingController _notesController = TextEditingController();
  final List<XFile> _attachedImages = [];
  final ImagePicker _picker = ImagePicker();

  // 3D Model State
  String _cameraTarget = 'auto 1.2m auto';
  String _cameraOrbit = '45deg 60deg 90%';
  double _zoomValue = 50.0; // 0.0 (wide) to 100.0 (zoom)
  bool _roofVis = true;

  // ── Sidebar animation ──
  late AnimationController _sidebarAnim;
  Timer? _pollTimer;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _attachedImages.add(image);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Design Tokens - Now using dynamic DashboardTheme
  Color get _bgMain => DashboardTheme.background;
  Color get _bgSidebar => DashboardTheme.surface;
  Color get _primaryBlue => DashboardTheme.primary;
  Color get _gold => DashboardTheme.accentAmber;
  Color get _textMain => DashboardTheme.textMain;
  Color get _textMuted => DashboardTheme.textSecondary;
  Color get _border => DashboardTheme.border;

  final List<SidebarItem> _navItems = [
    SidebarItem(
        index: 0, 
        icon: Icons.assignment_outlined, 
        label: TranslationService.instance.t('tech_nav_tasks')),
    SidebarItem(
        index: 1, 
        icon: Icons.calendar_month_outlined, 
        label: TranslationService.instance.t('tech_nav_schedule')),
    SidebarItem(
        index: 2, 
        icon: Icons.person_outline, 
        label: TranslationService.instance.t('tech_nav_profile')),
    SidebarItem(
        index: 3, 
        icon: Icons.settings_outlined, 
        label: TranslationService.instance.t('tech_nav_settings')),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    RepairRepository.instance.fetchHistory();
    _sidebarAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150), value: 0.0);
    _setupJsInterop();
  }

  void _setupJsInterop() {
    try {
      js.context['fcmDebugLogTech'] = (dynamic msg) {
        print("★★★ FCM_DEBUG_TECH: $msg ★★★");
      };

      js.context.callMethod('eval', [
        r"""
        (function() {
          const getScene = (mv) => {
             const syms = Object.getOwnPropertySymbols(mv);
             for (const s of syms) {
                const v = mv[s];
                if (v && (v.type === 'Scene' || v.scene?.type === 'Scene')) return v.scene || v;
             }
             return null;
          };

          function fcmCleanup() {
              if (window._fcmOverlays && window._fcmOverlays.length) {
                  window._fcmOverlays.forEach(ov => {
                      try {
                          if (ov && ov.parent) ov.parent.remove(ov);
                          if (ov && ov.material) ov.material.dispose();
                      } catch(_) {}
                  });
              }
              window._fcmOverlays = [];
          }

          function fcmMakeHighlight(refMat) {
              try {
                  const mat = new refMat.constructor();
                  // Apply only supported properties to avoid THREE console warnings
                  if (mat.color && typeof mat.color.setHex === 'function') {
                      mat.color.setHex(0xff0000);
                  }
                  mat.transparent = true;
                  mat.opacity = 0.8;
                  mat.depthTest = true;
                  mat.depthWrite = false;
                  mat.side = 2;
                  
                  if (mat.emissive && typeof mat.emissive.setHex === 'function') {
                      mat.emissive.setHex(0x880000);
                      mat.emissiveIntensity = 3.0;
                  }
                  return mat;
              } catch(e) { return null; }
          }

          function fcmOverlay(node) {
              if (!node || !node.isMesh || !node.geometry) return null;
              try {
                  const ref = Array.isArray(node.material) ? node.material[0] : node.material;
                  const mat = fcmMakeHighlight(ref || {});
                  if (!mat) return null;
                  const ov = new node.constructor(node.geometry, mat);
                  ov.position.copy(node.position);
                  ov.quaternion.copy(node.quaternion);
                  ov.scale.copy(node.scale);
                  ov.renderOrder = 999;
                  ov.matrixAutoUpdate = true;
                  if (node.parent) { node.parent.add(ov); return ov; }
              } catch(e) { console.error('[FCM-TECH] Overlay Error:', e); }
              return null;
          }

          window.fcmHighlightByName = function(nameKey) {
              const mv = document.getElementById('fcmTechModel');
              if (!mv) return;
              const scene = getScene(mv);
              if (!scene) {
                  console.warn('[FCM-TECH] Could not find 3D Scene');
                  return;
              }

              fcmCleanup();
              if (!nameKey || nameKey.toString().trim() === '') return;

              // Normalized target from DB: remove 'obj_', spaces, underscores
              const target = nameKey.toString().toLowerCase()
                                 .replace('obj_', '')
                                 .replace(/[\s\-_]/g, '')
                                 .trim();
              
              console.log("[FCM-TECH] DEBUG: Searching literal target '" + target + "'");

              let matchCount = 0;
              let allNames = [];
              
              scene.traverse(node => {
                  if (node.name) allNames.push(node.name);
                  
                  // Normalize node name in model
                  const n = (node.name||'').toLowerCase()
                                .replace(/\.\d+$/g, '')
                                .replace(/[\s\-_]/g, '')
                                .trim();
                  
                  // CHECK: Literal Match instead of includes
                  if (n === target) {
                      console.log('[FCM-TECH] EXACT MATCH:', node.name, '(' + node.type + ')');
                      
                      // Highlight recursively if it's a group, or just the mesh itself
                      node.traverse(child => {
                          if (child.isMesh) {
                              const ov = fcmOverlay(child);
                              if (ov) {
                                  window._fcmOverlays.push(ov);
                                  matchCount++;
                              }
                          }
                      });
                  }
              });

              if (matchCount === 0) {
                  console.warn('[FCM-TECH] No matches found for:', target);
                  console.log('[FCM-TECH] Sample available nodes:', allNames.slice(0, 10).join(', '));
              } else {
                  console.log('[FCM-TECH] Successfully highlighted ' + matchCount + ' literal matches.');
              }
          };

          window.fcmTechFocus = function(target) {
              const mv = document.getElementById('fcmTechModel');
              if (mv && target) mv.cameraTarget = target;
          };

          window.fcmSetZoom = function(v) {
              const mv = document.getElementById('fcmTechModel');
              if (mv) {
                  const fov = 90 - (v * 0.85);
                  mv.fieldOfView = fov + 'deg';
              }
          };

          window.fcmGetZoom = function() {
              const mv = document.getElementById('fcmTechModel');
              if (mv && mv.fieldOfView) {
                  const fov = parseFloat(mv.fieldOfView);
                  // Inverse logic: fov = 90 - (v * 0.85) => v = (90 - fov) / 0.85
                  const v = (90 - fov) / 0.85;
                  return Math.min(100, Math.max(0, v));
              }
              return null;
          };

          window.fcmToggleRoof = function(state) {
              const mv = document.getElementById('fcmTechModel');
              if (!mv) return;
              const scene = getScene(mv);
              if (!scene) return;
              scene.traverse(node => {
                  const l = (node.name||'').toLowerCase().trim();
                  if (l.includes('cube032') || l.includes('roof')) {
                      node.visible = state;
                  }
              });
          };
        })();
        """
      ]);

      // Add a poller to highlight once model is ready
      js.context.callMethod('eval', [
        r"""
        window.startTechHighlightPoll = function(nameKey) {
            console.log('[FCM-TECH] Starting poll for:', nameKey);
            let attempts = 0;
            const interval = setInterval(() => {
                const mv = document.getElementById('fcmTechModel');
                if (mv) {
                    // Try to get scene
                    const syms = Object.getOwnPropertySymbols(mv);
                    let hasScene = false;
                    for (const s of syms) {
                        if (mv[s] && (mv[s].type === 'Scene' || mv[s].scene?.type === 'Scene')) {
                            hasScene = true; break;
                        }
                    }
                    if (hasScene) {
                        console.log('[FCM-TECH] Model ready, highlighting...');
                        window.fcmHighlightByName(nameKey);
                        clearInterval(interval);
                    }
                }
                if (++attempts > 20) clearInterval(interval);
            }, 500);
        };
        """
      ]);
    } catch (e) {
      print("TECH JS Init Error: $e");
    }
    // ── 3D Zoom & State Polling ──
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final currentZoom = js.context.callMethod('fcmGetZoom');
        if (currentZoom != null) {
          final double newZoom = (currentZoom as num).toDouble();
          // Update only if change is significant to avoid slider jitter
          if ((newZoom - _zoomValue).abs() > 0.5) {
            setState(() => _zoomValue = newZoom);
          }
        }
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sidebarAnim.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarAnim.animateTo(1.0, curve: Curves.easeOutCubic);
    } else {
      _sidebarAnim.animateTo(0.0, curve: Curves.easeInCubic);
    }
  }

  void _closeSidebar() {
    if (_sidebarOpen) {
      setState(() => _sidebarOpen = false);
      _sidebarAnim.animateTo(0.0, curve: Curves.easeInCubic);
    }
  }

  List<RepairRequest> _getAssignedTasks(List<RepairRequest> allRepairs) {
    final searchName = _displayName.trim().toLowerCase();
    if (searchName == TranslationService.instance.t('loading').toLowerCase()) return [];

    return allRepairs.where((t) {
      return t.assignedStaff.any((s) => s.trim().toLowerCase() == searchName);
    }).toList();
  }

  bool _canStartWork(RepairRequest task) {
    if (task.appointmentDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final apptDay = DateTime(task.appointmentDate!.year,
        task.appointmentDate!.month, task.appointmentDate!.day);
    return !today.isBefore(apptDay);
  }

  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success']) {
      final data = result['data'];
      if (mounted) {
        setState(() {
          _displayName = (data['name'] ?? '').toString();
          _displayRole = (data['role'] ?? 'TECHNICIAN').toString();
          _displayEmail = (data['email'] ?? '').toString();
          _displayPhone = (data['phone'] ?? '').toString();
          _displayImage =
              (data['picture_uri'] ?? 'assets/resident_profile.png').toString();
        });
      }
    } else if (result['expired'] == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: _bgMain,
          body: Stack(
            children: [
              // ── Main Content ──
              Positioned.fill(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<List<RepairRequest>>(
                    valueListenable: RepairRepository.instance.repairsNotifier,
                    builder: (context, repairs, child) {
                      final assignedTasks = _getAssignedTasks(repairs);
                      return Column(
                        children: [
                          _buildHeader(assignedTasks),
                          Expanded(
                            child: _buildPageContent(_currentIndex, repairs),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Scrim ──
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_sidebarOpen,
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: AnimatedBuilder(
                      animation: _sidebarAnim,
                      builder: (context, _) => Container(
                        color:
                            Colors.black.withOpacity(0.45 * _sidebarAnim.value),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Sidebar ──
              AnimatedBuilder(
                animation: _sidebarAnim,
                builder: (context, child) {
                  const w = 260.0;
                  return Positioned(
                    top: 0,
                    bottom: 0,
                    left: -w + (w * _sidebarAnim.value),
                    width: w,
                    child: child!,
                  );
                },
                child: _buildSidebarContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    return Material(
      color: _bgSidebar,
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.instance.t('tech_portal'),
                    style: GoogleFonts.outfit(
                      color: _primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayName,
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _displayRole,
                    style: GoogleFonts.outfit(
                      color: DashboardTheme.textPale,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  )
                ],
              ),
            ),
            Divider(color: _border, height: 32),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, i) {
                  final item = _navItems[i];
                  final isSelected = _currentIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = i),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue.withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon,
                                size: 20,
                                color: isSelected
                                    ? _primaryBlue
                                    : DashboardTheme.textPale),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: GoogleFonts.outfit(
                                color: isSelected
                                    ? _primaryBlue
                                    : DashboardTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: InkWell(
                onTap: () => _showLogoutConfirmation(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: DashboardTheme.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 20,
                          color: DashboardTheme.error.withOpacity(0.8)),
                      const SizedBox(width: 14),
                      Text(
                        TranslationService.instance.t('logout'),
                        style: GoogleFonts.outfit(
                          color: DashboardTheme.error.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: DashboardTheme.cardDecoration().copyWith(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: DashboardTheme.error.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: DashboardTheme.error.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        DashboardTheme.error.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DashboardTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: DashboardTheme.error.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.power_settings_new_rounded,
                            color: DashboardTheme.error, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(TranslationService.instance.t('tech_logout_session_title'),
                          style: GoogleFonts.shareTechMono(
                              color: DashboardTheme.error,
                              fontSize: 18,
                              letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(
                        TranslationService.instance.t('tech_logout_confirmation'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          color: DashboardTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: BorderSide(
                                color:
                                    DashboardTheme.textPale.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(TranslationService.instance.t('cancel'),
                              style: GoogleFonts.notoSans(
                                  color: DashboardTheme.textPale,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await AuthRepository.instance.logout();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                  context, '/login', (route) => false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                DashboardTheme.error.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(TranslationService.instance.t('logout'),
                              style: GoogleFonts.notoSans(
                                  color: DashboardTheme.error,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<RepairRequest> assignedTasks) {
    final todayTasks = assignedTasks
        .where((t) =>
            t.status == "IN PROGRESS" ||
            t.status == "URGENT" ||
            t.status == "ASSIGNED")
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: _bgSidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _toggleSidebar,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(Icons.menu_rounded, color: _primaryBlue, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _navItems[_currentIndex].label == "ALL TASKS"
                        ? "Assigned Tasks"
                        : _navItems[_currentIndex].label,
                    style: GoogleFonts.kanit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: _textMain),
                  ),
                  Text(
                    TranslationService.instance.t('tech_header_tasks_today').replaceAll('{count}', todayTasks.toString()),
                    style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: _textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          // Clean Avatar in header
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: _primaryBlue.withOpacity(0.2), width: 2),
            ),
            child: ClipOval(
              child: _displayImage.startsWith('http')
                  ? Image.network(_displayImage, fit: BoxFit.cover)
                  : Image.asset(_displayImage, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index, List<RepairRequest> allRepairs) {
    switch (index) {
      case 0:
        if (_selectedTask != null) {
          return _buildTaskDetailView(_selectedTask!);
        }
        return _buildTasksPage(allRepairs);
      case 1:
        return _buildCalendarPage(allRepairs);
      case 2:
        return ProfileView(
          name: _displayName,
          email: _displayEmail,
          phone: _displayPhone,
          role: _displayRole,
          imagePath: _displayImage,
          onMenuTap: _toggleSidebar,
          onProfileUpdated: _fetchUserProfile,
        );
      case 3:
        return const SettingsView();
      default:
        return _buildTasksPage(allRepairs);
    }
  }

  // Removed redundant builders as they are now imported from shared views

  Widget _buildTasksPage(List<RepairRequest> allRepairs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final crossAxisCount = isMobile ? 1 : 3;
        final childAspectRatio = isMobile ? 1.6 : 1.2;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chip Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(TranslationService.instance.t('all'), _selectedTaskFilter == "All"),
                          const SizedBox(width: 16),
                          _filterChip(TranslationService.instance.t('status_assigned'), _selectedTaskFilter == "Assigned"),
                          const SizedBox(width: 16),
                          _filterChip(TranslationService.instance.t('status_in_progress'), _selectedTaskFilter == "In Progress"),
                          const SizedBox(width: 16),
                          _filterChip(TranslationService.instance.t('status_completed'), _selectedTaskFilter == "Completed"),
                          const SizedBox(width: 16),
                          _filterChip(TranslationService.instance.t('status_evaluated'), _selectedTaskFilter == "Evaluated"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(TranslationService.instance.t('tech_filter_repair_area'), 
                      style: GoogleFonts.kanit(
                        fontSize: 11, 
                        color: _gold, 
                        letterSpacing: 4, 
                        fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            (() {
              final rawTasks = _getAssignedTasks(allRepairs);
              final filteredTasks = rawTasks.where((t) {
                if (_selectedTaskFilter == "All") return true;
                if (_selectedTaskFilter == "Assigned")
                  return t.status == "ASSIGNED" || t.status == "URGENT";
                if (_selectedTaskFilter == "In Progress")
                  return t.status == "IN PROGRESS";
                if (_selectedTaskFilter == "Completed")
                  return t.status == "COMPLETED";
                if (_selectedTaskFilter == "Evaluated")
                  return t.status == "EVALUATED";
                return true;
              }).toList();

              if (filteredTasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Text(TranslationService.instance.t('tech_no_tasks_category'),
                          style: GoogleFonts.kanit(color: _textMuted)),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = filteredTasks[index];
                      final uiStatus = t.status.toLowerCase();
                      final displayStatus = t.status == "URGENT"
                          ? TranslationService.instance.t('status_urgent')
                          : (t.status == "IN PROGRESS"
                              ? TranslationService.instance.t('status_in_progress')
                              : (t.status == "COMPLETED"
                                  ? TranslationService.instance.t('status_completed')
                                  : (t.status == "EVALUATED"
                                      ? TranslationService.instance.t('status_evaluated')
                                      : (t.status == "CANCELED" ||
                                              t.status == "DECLINED"
                                          ? TranslationService.instance.t('status_canceled')
                                          : TranslationService.instance.t('status_assigned')))));

                      return _techWorkCard(t, uiStatus, displayStatus);
                    },
                    childCount: filteredTasks.length,
                  ),
                ),
              );
            })(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        );
      }
    );
  }

  Widget _buildCalendarPage(List<RepairRequest> allRepairs) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 1100;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40), // Standardized Margin
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(TranslationService.instance.t('tech_schedule_title'),
                style: GoogleFonts.kanit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _textMain)),
            const SizedBox(height: 8),
            Text(TranslationService.instance.t('tech_schedule_subtitle'),
                style: GoogleFonts.kanit(fontSize: 14, color: _textMuted)),
            const SizedBox(height: 32),

            if (!isMobile)
              // ── DESKTOP LAYOUT (Side-by-side) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Part 1: Calendar Grid (Flex 3)
                  Expanded(
                    flex: 3,
                    child: _calendarStack(allRepairs),
                  ),
                  const SizedBox(width: 32), // More margin
                  // Part 2: Selected Day Details (Flex 2)
                  Expanded(
                    flex: 2,
                    child: _buildDayDetailCard(allRepairs),
                  ),
                ],
              )
            else
              // ── MOBILE LAYOUT (Stacked) ──
              Column(
                children: [
                  _calendarStack(allRepairs),
                  const SizedBox(height: 32), // More margin
                  _buildDayDetailCard(allRepairs),
                ],
              ),

            const SizedBox(height: 48),

            // Part 3: Upcoming List (Full width)
            Text(TranslationService.instance.t('tech_upcoming_list'),
                style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textMain)),
            const SizedBox(height: 16),
            _buildUpcomingList(allRepairs),
            const SizedBox(height: 60), // Add padding for bottom navigation
          ],
        ),
      );
    });
  }

  Widget _calendarStack(List<RepairRequest> allRepairs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text("March 2026",
              style: GoogleFonts.kanit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildCalendarGrid(allRepairs),
          const SizedBox(height: 32),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<RepairRequest> allRepairs) {
    final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    
    return Column(
      children: [
        // Days labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: GoogleFonts.kanit(
                              fontSize: 12, color: _textMuted)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        
        // Calendar Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            return _calendarDay(index + 1, allRepairs);
          },
        ),
      ],
    );
  }

  Widget _calendarDay(int day, List<RepairRequest> allRepairs) {
    bool isSelected = _selectedCalendarDay == day;

    final assignedTasks = _getAssignedTasks(allRepairs);
    final dayTasks = assignedTasks.where((t) {
      if (t.appointmentDate == null) return false;
      // Filter for March (3) to match current mockup alignment
      return t.appointmentDate!.day == day && t.appointmentDate!.month == 3;
    }).toList();

    bool isUpcoming =
        dayTasks.any((t) => t.status == "IN PROGRESS" || t.status == "URGENT" || t.status == "ASSIGNED");

    Color bg = _bgSidebar;
    Color textColor = _textMain;
    BoxBorder border = Border.all(color: Colors.transparent);

    if (isSelected) {
      bg = const Color(0xFFFFF7ED); // Amber 50
      textColor = const Color(0xFFD97706); // Amber 600
      border = Border.all(color: const Color(0xFFF59E0B), width: 2);
    } else if (isUpcoming) {
      bg = const Color(0xFFECFDF5); // Green 50
      textColor = const Color(0xFF059669); // Green 600
    }

    return InkWell(
      onTap: () => setState(() => _selectedCalendarDay = day),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day.toString(),
                style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w600, color: textColor)),
            if (isUpcoming || isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(TranslationService.instance.t('upcoming'), const Color(0xFF10B981)),
        const SizedBox(width: 16),
        _legendItem(TranslationService.instance.t('selected'), const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
      ],
    );
  }

  Widget _buildDayDetailCard(List<RepairRequest> allRepairs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TranslationService.instance.t('tech_schedule_for'), // I forgot this key in service, will use inline if missing or update
              style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
          Text("$_selectedCalendarDay March 2026",
              style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706))),
          const SizedBox(height: 24),
          (() {
            final dayTasks = _getAssignedTasks(allRepairs).where((t) {
              if (t.appointmentDate == null) return false;
              // Compare day, month, and year with selected calendar day
              // For now, mockup month is always March (3) as per current design,
              // but we use DateTime's month to be safe.
              return t.appointmentDate!.day == _selectedCalendarDay &&
                  t.appointmentDate!.month ==
                      3; // Keep alignment with mockup month
            }).toList();

            if (dayTasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("No tasks for this day",
                      style: GoogleFonts.kanit(color: _textMuted)),
                ),
              );
            }

            return Column(
              children: dayTasks.map((t) {
                final displayStatus = t.status == "URGENT"
                    ? "Urgent"
                    : (t.status == "IN PROGRESS"
                        ? "Working"
                        : (t.status == "COMPLETED"
                            ? "Completed"
                            : (t.status == "EVALUATED"
                                ? "Evaluated"
                                : "Pending")));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showTaskDetails(t),
                    borderRadius: BorderRadius.circular(12),
                    child: _compactTaskTile(
                        t.title, displayStatus, t.requesterHouse ?? 'N/A', t.id),
                  ),
                );
              }).toList(),
            );
          })(),
        ],
      ),
    );
  }

  Widget _compactTaskTile(
      String title, String status, String house, String id) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _gold, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withOpacity(DashboardTheme.isDarkMode.value ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: GoogleFonts.kanit(
                        color: _primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold, color: _textMain)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.home_outlined, size: 12, color: _textMuted),
              const SizedBox(width: 4),
              Text("House: $house",
                  style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList(List<RepairRequest> allRepairs) {
    final upcomingItems = _getAssignedTasks(allRepairs)
        .where((t) =>
            t.status == "ASSIGNED" ||
            t.status == "URGENT" ||
            t.status == "IN PROGRESS")
        .toList();

    // Sort chronologically by appointmentDate
    upcomingItems.sort((a, b) {
      if (a.appointmentDate == null && b.appointmentDate == null) return 0;
      if (a.appointmentDate == null) return 1;
      if (b.appointmentDate == null) return -1;
      return a.appointmentDate!.compareTo(b.appointmentDate!);
    });

    if (upcomingItems.isEmpty) {
      return Center(
        child: Text("No upcoming tasks",
            style: GoogleFonts.kanit(color: _textMuted)),
      );
    }

    return Column(
      children: upcomingItems.map((t) {
        return InkWell(
          onTap: () => _showTaskDetails(t),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: _bgSidebar,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title,
                          style: GoogleFonts.kanit(
                              fontWeight: FontWeight.bold, color: _textMain)),
                      if (t.appointmentDate != null)
                        Text(
                          "Appointment: ${t.appointmentDate!.day}/${t.appointmentDate!.month}/${t.appointmentDate!.year}",
                          style: GoogleFonts.kanit(
                              fontSize: 12,
                              color: _primaryBlue.withOpacity(0.8)),
                        )
                      else
                        Text(t.date,
                            style: GoogleFonts.kanit(
                                fontSize: 12, color: _textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _textMuted),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTaskDetails(RepairRequest task) {
    setState(() {
      _selectedTask = task;
      _currentIndex = 0; // Switch to Main/Tasks page to reveal detail view
    });
    // Trigger highlighting for ALL objects in this request
    if (task.tasks.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          for (final t in task.tasks) {
            String? highlightKey = t.objectId;
            if (highlightKey == null || highlightKey.trim().isEmpty) {
              highlightKey = t.objectName;
            }
            
            if (highlightKey != null && highlightKey.trim().isNotEmpty) {
              debugPrint("FCM: Triggering highlight for key: '$highlightKey'");
              js.context.callMethod('startTechHighlightPoll', [highlightKey.trim()]);
            }
          }
        } catch (e) {}
      });
    }
  }

  Widget _buildTaskDetailView(RepairRequest task) {
    final statusColor = task.status == 'URGENT'
        ? const Color(0xFFFF3333)
        : task.status == 'IN PROGRESS'
            ? _gold
            : (task.status == 'COMPLETED' || task.status == 'EVALUATED')
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B);
    final statusLabel = task.status;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BACK NAV ──
          InkWell(
            onTap: () => setState(() => _selectedTask = null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.west_rounded, size: 18, color: _textMuted),
                const SizedBox(width: 10),
                Text("BACK",
                    style: GoogleFonts.kanit(
                        color: _textMuted,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ── HERO TITLE — Oversized, editorial ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thick status accent bar
              Container(
                width: 6,
                height: 72,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiny label
                    Text(
                        "${task.id}  ·  ${task.tasks.isNotEmpty ? task.tasks.first.urgency : ''}"
                            .toUpperCase(),
                        style: GoogleFonts.kanit(
                            fontSize: 11,
                            color: _textMuted,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    // MASSIVE title
                    Text(task.title,
                        style: GoogleFonts.kanit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: _textMain,
                            height: 1.1,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
              // Status badge — clean
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel.toUpperCase(),
                    style: GoogleFonts.kanit(
                        color:
                            statusColor == _gold ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 2)),
              ),
            ],
          ),

          const SizedBox(height: 48),

          // ── MAIN CONTENT ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;

              final leftColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ▌ REQUESTER — Bold name, clean info
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold, width: 2),
                        ),
                        child: ClipOval(
                          child: (task.requesterProfileUrl != null &&
                                  task.requesterProfileUrl!.isNotEmpty)
                              ? Image.network(
                                  task.requesterProfileUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: _gold.withOpacity(0.5)),
                                )
                              : Icon(Icons.person_rounded,
                                  size: 32, color: _gold.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.requesterName ?? "Unknown Requester",
                                style: GoogleFonts.kanit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _textMain)),
                            const SizedBox(height: 4),
                            Text(
                                "${task.requesterHouse ?? 'N/AAddress'}  ·  ${task.requesterPhone ?? ''}  ·  ${task.requesterEmail ?? ''}  ·  ${task.appointmentDate != null ? 'Appt: ' + task.appointmentDate!.day.toString() + '/' + task.appointmentDate!.month.toString() + '/' + task.appointmentDate!.year.toString() : 'Created: ' + task.date}",
                                style: GoogleFonts.kanit(
                                    fontSize: 13,
                                    color: _textMuted,
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(TranslationService.instance.t('tech_jobs_objects'),
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  if (task.tasks.isEmpty)
                    Text("No specific tasks listed.",
                        style: GoogleFonts.kanit(color: _textMuted))
                  else
                    ...task.tasks.map((t) => _buildTaskItem(t, task.status)),

                  const SizedBox(height: 32),
                  Container(height: 1, width: 80, color: _gold.withOpacity(0.4)),

                  const SizedBox(height: 40),

                  // ▌ 3D VIEW — Clean, dark
                  Text(TranslationService.instance.t('tech_filter_repair_area'),
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Container(
                    height: isMobile ? 350 : 500,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ModelViewer(
                        key: ValueKey('fcm_tech_view_${task.id}'),
                        id: 'fcmTechModel',
                        src: 'https://pub-5833e74343ce47749743badfb0438a50.r2.dev/Vivorn7.8.glb',
                        alt: TranslationService.instance.t('tech_filter_repair_area'),
                        autoRotate: false,
                        cameraControls: true,
                        disableZoom: true,
                        backgroundColor: Colors.transparent,
                        exposure: 1.2,
                        shadowIntensity: 1.0,
                        loading: Loading.eager,
                        cameraTarget: _cameraTarget,
                        cameraOrbit: _cameraOrbit,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── 3D CONTROL BAR ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _bgSidebar.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border.withOpacity(0.3)),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        // Zoom Section
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_out, size: 18, color: _textMuted),
                            SizedBox(
                              width: isMobile ? 120 : 180,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: _gold,
                                  inactiveTrackColor: _gold.withOpacity(0.2),
                                  thumbColor: _gold,
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: _zoomValue,
                                  min: 0,
                                  max: 100,
                                  onChanged: (v) {
                                    setState(() => _zoomValue = v);
                                    try {
                                      js.context.callMethod('fcmSetZoom', [v]);
                                    } catch (e) {}
                                  },
                                ),
                              ),
                            ),
                            Icon(Icons.zoom_in, size: 18, color: _textMuted),
                          ],
                        ),
                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMiniToolButton(
                              icon: _roofVis ? Icons.roofing_rounded : Icons.home_rounded,
                              label: _roofVis ? TranslationService.instance.t('tech_btn_hide_roof') : TranslationService.instance.t('tech_btn_show_roof'),
                              onTap: () {
                                setState(() => _roofVis = !_roofVis);
                                try {
                                  js.context.callMethod('fcmToggleRoof', [_roofVis]);
                                } catch (e) {}
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildMiniToolButton(
                              icon: Icons.center_focus_strong_rounded,
                              label: TranslationService.instance.t('tech_btn_reset_view'),
                              onTap: () {
                                setState(() {
                                  _cameraTarget = 'auto 1.2m auto';
                                  _cameraOrbit = '45deg 60deg 90%';
                                  _zoomValue = 50.0;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) const SizedBox(height: 48),
                  Text(TranslationService.instance.t('status_label_header'), // I'll add this to service mapping if missing or use STATUS
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _stepper([
                    _StepData(TranslationService.instance.t('status_assigned'), task.date, true),
                    _StepData(
                        TranslationService.instance.t('status_began'),
                        TranslationService.instance.t('tech_step_work_started'),
                        task.status == 'IN PROGRESS' ||
                            task.status == 'COMPLETED' ||
                            task.status == 'EVALUATED'),
                    _StepData(
                        TranslationService.instance.t('status_completed'),
                        TranslationService.instance.t('tech_step_work_finished'),
                        task.status == 'COMPLETED' ||
                            task.status == 'EVALUATED'),
                    _StepData(TranslationService.instance.t('status_evaluated'), TranslationService.instance.t('tech_step_feedback'),
                        task.status == 'EVALUATED'),
                  ]),

                  const SizedBox(height: 40),

                  if (task.status == 'ASSIGNED' ||
                      task.status == 'URGENT' ||
                      task.status == 'CREATED')
                    _actionBlock(
                      icon: Icons.play_arrow_rounded,
                      label: _canStartWork(task) ? TranslationService.instance.t('tech_btn_start_work') : TranslationService.instance.t('tech_btn_upcoming_appt'),
                      color: _canStartWork(task)
                          ? DashboardTheme.primary
                          : DashboardTheme.textPale.withOpacity(0.2),
                      textColor: _canStartWork(task)
                          ? Colors.white
                          : DashboardTheme.textSecondary,
                      onPressed: _canStartWork(task)
                          ? () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: DashboardTheme.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(TranslationService.instance.t('tech_dialog_start_title'),
                                style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textMain,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            content: Text(TranslationService.instance.t('tech_dialog_start_body').replaceAll('{title}', task.title),
                                style: GoogleFonts.notoSans(
                                    color: DashboardTheme.textSecondary,
                                    fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(TranslationService.instance.t('cancel'),
                                    style: GoogleFonts.notoSans(
                                        color: DashboardTheme.textPale,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final pinOk =
                                      await showPinVerificationOverlay(context);
                                  if (pinOk != true) return;

                                  bool success = await RepairRepository.instance
                                      .updateStatus(task.id, 'BEGAN');
                                  if (success) {
                                    if (mounted) {
                                      final updated = RepairRepository
                                          .instance.repairsNotifier.value
                                          .firstWhere((r) => r.id == task.id,
                                              orElse: () => task);
                                      setState(() => _selectedTask = updated);
                                    }
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                TranslationService.instance.t('error_occurred'))));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DashboardTheme.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(TranslationService.instance.t('tech_btn_start_work'),
                                    style: GoogleFonts.notoSans(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        );
                      }
                      : null,
                    )
                  else if (task.status == 'IN PROGRESS')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DashboardTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: DashboardTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded,
                                  color: DashboardTheme.primary, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(TranslationService.instance.t('tech_turn_in_title'),
                                      style: GoogleFonts.notoSans(
                                          color: DashboardTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5)),
                                  Text(TranslationService.instance.t('tech_turn_in_subtitle'),
                                      style: GoogleFonts.notoSans(
                                          color: DashboardTheme.textPale,
                                          fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _actionBlock(
                          icon: Icons.check_circle_outline_rounded,
                          label: TranslationService.instance.t('tech_btn_submit_finish'),
                          color: const Color(0xFF10B981),
                          textColor: Colors.white,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: DashboardTheme.surface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text(TranslationService.instance.t('tech_dialog_finish_title'),
                                    style: GoogleFonts.notoSans(
                                        color: DashboardTheme.textMain,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(TranslationService.instance.t('tech_dialog_finish_body').replaceAll('{title}', task.title),
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textSecondary,
                                            fontSize: 13)),
                                    const SizedBox(height: 12),
                                    if (_attachedImages.isNotEmpty)
                                      Text(
                                          TranslationService.instance.t('tech_attachments_count').replaceAll('{count}', _attachedImages.length.toString()),
                                          style: GoogleFonts.notoSans(
                                              color: DashboardTheme.primary,
                                              fontSize: 12)),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(TranslationService.instance.t('cancel'),
                                        style: GoogleFonts.notoSans(
                                            color: DashboardTheme.textPale,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      bool allReported = task.tasks.every((t) =>
                                          t.taskReport != null &&
                                          t.taskReport!.isNotEmpty);

                                      if (!allReported) {
                                        bool confirm = await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor:
                                                DashboardTheme.surface,
                                            title: Text(TranslationService.instance.t('tech_report_incomplete_title'),
                                                style: GoogleFonts.notoSans(
                                                    color: DashboardTheme
                                                        .textMain)),
                                            content: Text(
                                                TranslationService.instance.t('tech_report_incomplete_body')),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: Text(TranslationService.instance.t('tech_btn_back_form'))),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: Text(TranslationService.instance.t('tech_dialog_finish_title'))),
                                            ],
                                          ),
                                        );
                                        if (confirm != true) return;
                                      }

                                      Navigator.pop(ctx);
                                      final pinOk =
                                          await showPinVerificationOverlay(
                                              context);
                                      if (pinOk != true) return;

                                      bool success = await RepairRepository
                                          .instance
                                          .updateStatus(task.id, 'COMPLETED');
                                      if (success) {
                                        if (mounted) {
                                          setState(() => _selectedTask = null);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(TranslationService.instance.t('tech_submit_success'))));
                                        }
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "เกิดข้อผิดพลาดในการส่งงาน")));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: Text("ส่งงาน",
                                        style: GoogleFonts.notoSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  else if (task.status == 'COMPLETED' ||
                      task.status == 'EVALUATED')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text("COMPLETED ✓",
                            style: GoogleFonts.kanit(
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 2)),
                      ),
                    ),

                  const SizedBox(height: 48),

                  Text("NOTES",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    style: GoogleFonts.kanit(
                        color: _textMain, fontSize: 14, height: 1.6),
                    decoration: InputDecoration(
                      hintText: "Repair observations...",
                      hintStyle: GoogleFonts.kanit(
                          fontSize: 14, color: _textMuted.withOpacity(0.3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _gold.withOpacity(0.6)),
                      ),
                      filled: true,
                      fillColor: _bgSidebar,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text("ATTACHMENTS",
                      style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: _gold,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_attachedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachedImages.asMap().entries.map((e) {
                          return Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _bgSidebar,
                                  border: Border.all(
                                      color: _border.withOpacity(0.5)),
                                  image: DecorationImage(
                                    image: kIsWeb
                                        ? NetworkImage(e.value.path)
                                            as ImageProvider
                                        : FileImage(File(e.value.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () => setState(
                                      () => _attachedImages.removeAt(e.key)),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                   InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _border.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 28, color: _textMuted.withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text(TranslationService.instance.t('tech_attachments_label').toUpperCase(),
                              style: GoogleFonts.kanit(
                                  fontSize: 11,
                                  color: _textMuted.withOpacity(0.4),
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isMobile) {
                return Column(
                  children: [leftColumn, rightColumn],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 48),
                    SizedBox(width: 320, child: rightColumn),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _gold.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _gold, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.kanit(
                color: _gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bold action block — solid color, no gradient fuss
  Widget _actionBlock({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.kanit(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _filterChip(String label, bool active) {
    return InkWell(
      onTap: () => setState(() => _selectedTaskFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : _bgSidebar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _primaryBlue : _border),
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            color: active ? Colors.white : _textMain,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _techWorkCard(RepairRequest t, String uiStatus, String displayStatus) {
    String category = t.tasks.isNotEmpty ? t.tasks.first.urgency : "General";

    Color statusColor = const Color(0xFFF59E0B); // Pending (Gold)
    if (uiStatus == 'in progress')
      statusColor = const Color(0xFF10B981); // Working (Green)
    if (uiStatus == 'completed' || uiStatus == 'evaluated')
      statusColor = const Color(0xFF3B82F6); // Done (Blue)
    if (uiStatus == 'urgent')
      statusColor = const Color(0xFFFF3333); // Urgent (Red)

    return InkWell(
      onTap: () => _showTaskDetails(t),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _bgSidebar,
          border: Border.all(color: _border.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── TOP HEADER (Raw color block) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                border: Border(
                    bottom: BorderSide(color: statusColor.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category.toUpperCase(),
                      style: GoogleFonts.kanit(
                          color: _textMain.withOpacity(0.7),
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  Text(displayStatus.toUpperCase(),
                      style: GoogleFonts.kanit(
                          color: statusColor,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),

            // ── CONTENT BODY ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thick accent mark
                    Container(
                      width: 24,
                      height: 4,
                      color: statusColor,
                      margin: const EdgeInsets.only(bottom: 16),
                    ),
                    Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                            color: _textMain)),
                    const Spacer(),

                    // Details
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text("${t.requesterHouse ?? 'N/A'}",
                            style: GoogleFonts.kanit(
                                fontSize: 13,
                                color: _textMuted,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 14, color: _textMuted),
                        const SizedBox(width: 8),
                        Text(
                            t.appointmentDate != null
                                ? "${t.appointmentDate!.day}/${t.appointmentDate!.month}/${t.appointmentDate!.year}"
                                : t.date,
                            style: GoogleFonts.kanit(
                                fontSize: 12,
                                color: _textMuted.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── ACTION BUTTON (Full width, bold) ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _bgMain,
                border:
                    Border(top: BorderSide(color: _border.withOpacity(0.3))),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        (t.status == 'ASSIGNED' || t.status == 'URGENT')
                            ? (_canStartWork(t) ? "START WORK" : "UPCOMING")
                            : (t.status == 'IN PROGRESS'
                                ? "CONTINUE WORK"
                                : "VIEW DETAILS"),
                        style: GoogleFonts.kanit(
                            color: (t.status == 'ASSIGNED' || t.status == 'URGENT')
                                ? (_canStartWork(t) ? _primaryBlue : _textMuted)
                                : _gold,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14,
                        color: (t.status == 'ASSIGNED' || t.status == 'URGENT')
                            ? (_canStartWork(t) ? _primaryBlue : _textMuted)
                            : _gold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(RepairTask t, String requestStatus) {
    final bool hasReport = t.taskReport != null && t.taskReport!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSidebar.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasReport
                ? Colors.green.withOpacity(0.3)
                : _border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasReport ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 18,
                color: hasReport ? Colors.green : _gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.objectName ?? t.description,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (hasReport)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(
                t.taskReport!,
                style: GoogleFonts.kanit(
                  fontSize: 13,
                  color: _textMain.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepper(List<_StepData> steps) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        // Determine if this is the current "active" step (first incomplete one)
        final isActive = !s.done && (i == 0 || steps[i - 1].done);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: s.done
                        ? (i == steps.length - 1
                            ? const Color(0xFF10B981)
                            : _gold)
                        : (isActive
                            ? _gold.withOpacity(0.15)
                            : Colors.transparent),
                    border: Border.all(
                        color: s.done
                            ? Colors.transparent
                            : (isActive ? _gold : _border),
                        width: 2),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: _gold.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 1)
                          ]
                        : [],
                  ),
                  child: s.done
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : (isActive
                          ? Center(
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: _gold, shape: BoxShape.circle)))
                          : null),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: s.done
                            ? [_gold, _gold.withOpacity(0.5)]
                            : [_border, _border],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: GoogleFonts.kanit(
                          fontWeight: FontWeight.bold,
                          fontSize: isActive ? 15 : 14,
                          color: s.done
                              ? _textMain
                              : (isActive ? _gold : _textMuted))),
                  Text(s.sub,
                      style:
                          GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StepData {
  final String title;
  final String sub;
  final bool done;
  _StepData(this.title, this.sub, this.done);
}
