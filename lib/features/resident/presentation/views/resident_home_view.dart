import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:fcm_app/features/chat/presentation/widgets/ai_chat_panel.dart';
import 'package:fcm_app/core/services/translation_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// ═══════════════════════════════════════════════════════════
// Resident Home — Premium Always-On Display (V16.0: Final Polish & Accurate Logic)
// ═══════════════════════════════════════════════════════════

class ResidentHomeView extends StatefulWidget {
  final String displayUser;
  final String houseId;
  final bool isDark;
  final VoidCallback? onMenuTap;
  final VoidCallback? onHistoryRequested;

  const ResidentHomeView({
    super.key,
    required this.displayUser,
    required this.houseId,
    required this.isDark,
    this.onMenuTap,
    this.onHistoryRequested,
  });

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView> with TickerProviderStateMixin {
  // ── UI State ──
  late Timer _clockTimer;
  String _timeStr = '';
  String _dateStr = '';
  String _greeting = '';
  late AnimationController _tickerAnim;
  bool _showTicker = true;
  bool _showAIChatPanel = false;

  // ── Repair Flow & Aesthetic State ──
  late AnimationController _popupAnim;
  bool _showRepairPopup = false;
  String _selectedObjectName = '';
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _isUrgent = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  String _selectedCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _attachedImages = [];
  bool _showConfirmation = false;
  
  final ValueNotifier<Offset> _popupOffset = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);
  
  // Draggable FAB State (Starts at Header position)
  final ValueNotifier<Offset> _repairFabOffset = ValueNotifier<Offset>(const Offset(40, 110));
  final ValueNotifier<bool> _isRepairFabDragging = ValueNotifier<bool>(false);

  // ── Camera State ──
  String _cameraTarget = 'auto 1.2m auto';
  String _cameraOrbit = '45deg 60deg 90%';
  final ImagePicker _picker = ImagePicker();

  final _categories = [
    {'group': 'Bathroom', 'items': ['Bathtub', 'Toilet', 'Water Heater', 'Basin/Mirror']},
    {'group': 'Kitchen', 'items': ['Refrigerator', 'Oven', 'Dishwasher', 'Sink/Stove']},
    {'group': 'Living Room', 'items': ['Air Conditioner', 'TV/Display', 'Smart Panel']},
    {'group': 'Infrastructure', 'items': ['Doors/Windows', 'Lighting', 'Plumbing']},
  ];

  final List<_Announcement> _announcements = const [
    _Announcement(icon: Icons.water_drop_rounded, color: Color(0xFF60A5FA), text: 'Water Tank Cleaning — Water off 09:00 – 12:00 (Feb 15)'),
    _Announcement(icon: Icons.bug_report_rounded, color: Color(0xFFFBBF24), text: 'Mosquito Spraying — Close all windows & doors (Feb 20)'),
    _Announcement(icon: Icons.groups_rounded, color: Color(0xFF34D399), text: 'Annual General Meeting — Clubhouse, 6:00 PM (Feb 25)'),
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _tickerAnim = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _popupAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _setupJsInterop();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _tickerAnim.dispose();
    _popupAnim.dispose();
    _titleCtrl.dispose();
    _detailCtrl.dispose();
    _popupOffset.dispose();
    _isDragging.dispose();
    _repairFabOffset.dispose();
    _isRepairFabDragging.dispose();
    super.dispose();
  }

  void _setupJsInterop() {
    try {
      js.context['onHomeObjectClicked'] = (dynamic name) { if (mounted) _handleObjectClick(name); };
      js.context.callMethod('eval', [r"""
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

          window.fcmFocus = function(target, zoomFactor) {
              const mv = document.getElementById('fcmHouseModel');
              if (mv) {
                  if (target) mv.cameraTarget = target;
                  const currentOrbit = mv.getCameraOrbit();
                  if (currentOrbit && zoomFactor) {
                      const newRadius = currentOrbit.radius * zoomFactor;
                      mv.cameraOrbit = `${currentOrbit.theta}rad ${currentOrbit.phi}rad ${newRadius}m`;
                  }
              }
          };

          window.fcmReset = function() {
              const mv = document.getElementById('fcmHouseModel');
              if (mv) {
                  mv.cameraTarget = 'auto 1.2m auto';
                  mv.cameraOrbit = '45deg 60deg 90%';
              }
          };

          window.toggleRoof = function() {
              if (window._fcmRoofVis === undefined) window._fcmRoofVis = true;
              window._fcmRoofVis = !window._fcmRoofVis;
              const state = window._fcmRoofVis;
              document.querySelectorAll('model-viewer').forEach(mv => {
                  const scene = getScene(mv); if(!scene)return;
                  scene.traverse(node => {
                      const l=(node.name||'').toLowerCase().trim();
                      if(l.includes('cube032')||l.includes('cube_032')||l.includes('cube.032')||l.includes('roof')) node.visible=state;
                  });
              });
          };

          function fcmMakeHighlight(refMat) {
              try {
                  const C = refMat.constructor;
                  return new C({
                      color: 0xff7700, transparent: true, opacity: 0.75,
                      emissive: 0xaa4400, emissiveIntensity: 2.0,
                      depthTest: true, depthWrite: false,
                      polygonOffset: true, polygonOffsetFactor: -4, polygonOffsetUnits: -4,
                      side: 2
                  });
              } catch(_) { return null; }
          }

          function fcmOverlay(mesh) {
              if (!mesh || !mesh.isMesh || !mesh.geometry) return null;
              try {
                  const ref = Array.isArray(mesh.material) ? mesh.material[0] : mesh.material;
                  const mat = fcmMakeHighlight(ref);
                  if (!mat) return null;
                  const ov = new mesh.constructor(mesh.geometry, mat);
                  ov.position.copy(mesh.position);
                  ov.quaternion.copy(mesh.quaternion);
                  ov.scale.copy(mesh.scale);
                  ov.renderOrder = 999;
                  if (mesh.parent) { mesh.parent.add(ov); return ov; }
              } catch(e) {}
              return null;
          }

          function fcmUnproject(nx, ny, nz, cam) {
              const pi = cam.projectionMatrixInverse.elements;
              const cw = cam.matrixWorld.elements;
              const w = pi[3]*nx + pi[7]*ny + pi[11]*nz + pi[15];
              const cx = (pi[0]*nx + pi[4]*ny + pi[8]*nz + pi[12]) / w;
              const cy = (pi[1]*nx + pi[5]*ny + pi[9]*nz + pi[13]) / w;
              const cz = (pi[2]*nx + pi[6]*ny + pi[10]*nz + pi[14]) / w;
              return {
                  x: cw[0]*cx + cw[4]*cy + cw[8]*cz + cw[12],
                  y: cw[1]*cx + cw[5]*cy + cw[9]*cz + cw[13],
                  z: cw[2]*cx + cw[6]*cy + cw[10]*cz + cw[14]
              };
          }

          window.setupFcmSelection = function() {
              document.querySelectorAll('model-viewer').forEach(mv => {
                  if (mv._fcmV15) return;
                  mv._fcmV15 = true;
                  mv.setAttribute('zoom-sensitivity', '0.3');

                  mv.addEventListener('click', (event) => {
                      fcmCleanup();
                      const hitData = mv.positionAndNormalFromPoint(event.clientX, event.clientY);
                      if (!hitData || !hitData.position) return;

                      const scene = getScene(mv); if (!scene) return;
                      let camera = null;
                      Object.getOwnPropertySymbols(mv).forEach(s => {
                          if (mv[s] && mv[s].camera) camera = mv[s].camera;
                      });
                      if (!camera) return;

                      const rect = mv.getBoundingClientRect();
                      const ndcX = ((event.clientX - rect.left) / rect.width) * 2 - 1;
                      const ndcY = -((event.clientY - rect.top) / rect.height) * 2 + 1;

                      camera.updateMatrixWorld(true);
                      const nearPt = fcmUnproject(ndcX, ndcY, -1, camera);
                      const farPt  = fcmUnproject(ndcX, ndcY,  1, camera);
                      const rayOrigin = camera.position;
                      let rdx = farPt.x - nearPt.x, rdy = farPt.y - nearPt.y, rdz = farPt.z - nearPt.z;
                      const rLen = Math.sqrt(rdx*rdx + rdy*rdy + rdz*rdz);
                      rdx /= rLen; rdy /= rLen; rdz /= rLen;

                      let targetMesh = null, closestDist = Infinity;
                      scene.traverse(node => {
                          if (!node.isMesh || !node.visible) return;
                          node.updateMatrixWorld(true);
                          const inv = node.matrixWorld.clone().invert();
                          const el = inv.elements;
                          const loX = rayOrigin.x*el[0]+rayOrigin.y*el[4]+rayOrigin.z*el[8]+el[12];
                          const loY = rayOrigin.x*el[1]+rayOrigin.y*el[5]+rayOrigin.z*el[9]+el[13];
                          const loZ = rayOrigin.x*el[2]+rayOrigin.y*el[6]+rayOrigin.z*el[10]+el[14];
                          const ldx = rdx*el[0]+rdy*el[4]+rdz*el[8];
                          const ldy = rdx*el[1]+rdy*el[5]+rdz*el[9];
                          const ldz = rdx*el[2]+rdy*el[6]+rdz*el[10];

                          const posAttr = node.geometry.attributes.position;
                          const arr = posAttr.array;
                          const idxAttr = node.geometry.index;
                          let minT = Infinity;

                          const checkTri = (i0, i1, i2) => {
                              const v0x=arr[i0*3], v0y=arr[i0*3+1], v0z=arr[i0*3+2];
                              const v1x=arr[i1*3], v1y=arr[i1*3+1], v1z=arr[i1*3+2];
                              const v2x=arr[i2*3], v2y=arr[i2*3+1], v2z=arr[i2*3+2];
                              const e1x=v1x-v0x, e1y=v1y-v0y, e1z=v1z-v0z;
                              const e2x=v2x-v0x, e2y=v2y-v0y, e2z=v2z-v0z;
                              const hx=ldy*e2z-ldz*e2y, hy=ldz*e2x-ldx*e2z, hz=ldx*e2y-ldy*e2x;
                              const a = e1x*hx+e1y*hy+e1z*hz; if(a>-1e-6 && a<1e-6) return;
                              const f=1/a, sx=loX-v0x, sy=loY-v0y, sz=loZ-v0z, u=f*(sx*hx+sy*hy+sz*hz);
                              if(u<0||u>1)return;
                              const qx=sy*e1z-sz*e1y, qy=sz*e1x-sx*e1z, qz=sx*e1y-sy*e1x, v=f*(ldx*qx+ldy*qy+ldz*qz);
                              if(v<0||u+v>1)return;
                              const t=f*(e2x*qx+e2y*qy+e2z*qz); if(t>1e-6) minT=Math.min(minT, t);
                          };

                          if(idxAttr){ const a=idxAttr.array; for(let i=0; i<a.length; i+=3) checkTri(a[i],a[i+1],a[i+2]); }
                          else { for(let i=0; i<arr.length/3; i+=3) checkTri(i,i+1,i+2); }

                          if(minT<closestDist){ closestDist=minT; targetMesh=node; }
                      });

                      if(targetMesh){
                          let bestNode = targetMesh;
                          let curr = targetMesh.parent;
                          const hierarchySkip = ['scene', 'target', 'root', 'model', 'house', 'main', 'base'];
                          const selectionIgnore = ['wall', 'floor', 'ceiling', 'bed', 'vase', 'plant', 'table', 'carpet', 'rug', 'curtain', 'blind', 'glass', 'stone', 'louvers', 'pillar', 'beam', 'brick', 'stair', 'grass', 'ground', 'sky', 'fence'];
                          
                          while(curr && curr.type !== 'Scene'){
                              if(curr.name) {
                                  const cName = curr.name.toLowerCase();
                                  if (hierarchySkip.some(s => cName === s)) break;
                                  if (cName.includes('roof') || cName.includes('window') || cName.includes('door') || cName.includes('ac') || cName.includes('toilet') || cName.includes('sink') || cName.includes('tub') || cName.includes('machine') || cName.includes('fridge')) {
                                      bestNode = curr; break; 
                                  }
                              }
                              curr = curr.parent;
                          }
                          
                          const cNameFinal = (bestNode.name||'').toLowerCase();
                          const shouldIgnore = selectionIgnore.some(s => cNameFinal.includes(s));
                          if(shouldIgnore) return;

                          window._fcmOverlays = [];
                          if (bestNode.isMesh) {
                              const ov = fcmOverlay(bestNode); if(ov) window._fcmOverlays.push(ov);
                          } else {
                              bestNode.traverse(ch => { if(ch.isMesh && ch.visible){ const ov = fcmOverlay(ch); if(ov) window._fcmOverlays.push(ov); } });
                          }
                          if(window.onHomeObjectClicked){
                             const p = hitData.position;
                             window.onHomeObjectClicked(JSON.stringify({
                                name: bestNode.name || targetMesh.name,
                                focus: `${p.x.toFixed(3)}m ${p.y.toFixed(3)}m ${p.z.toFixed(3)}m`
                             }));
                          }
                      }
                  });
              });
          };
          setInterval(() => window.setupFcmSelection(), 1000);
        })();
        """
      ]);
    } catch (e) {}
  }

  void _handleObjectClick(dynamic raw) {
    try {
      final data = jsonDecode(raw);
      final rawName = data['name'] ?? '';
      final displayName = _formatObjectName(rawName);
      setState(() {
        _selectedObjectName = displayName;
        _cameraTarget = data['focus'];
        _repairFabOffset.value = const Offset(40, 110); // Reset to Header position on selection
        _titleCtrl.text = displayName;
        _showSuccess = false;
        _showConfirmation = false;
        _showRepairPopup = true;
      });
      _popupAnim.forward(from: 0.0);
      js.context.callMethod('fcmFocus', [_cameraTarget, 0.7]);
    } catch(e) {}
  }

  String _formatObjectName(String rawName) {
    final lower = rawName.toLowerCase();
    final Map<String, String> detailedMap = {
      'plane.008': 'Sec Bedroom Wall 1', 'plane008': 'Sec Bedroom Wall 1',
      'plane.012': 'Sec Bedroom Wall 2', 'plane012': 'Sec Bedroom Wall 2',
      'plane.007': 'Sec Bedroom Wall 3', 'plane007': 'Sec Bedroom Wall 3',
      'plane.025': 'Sec Bedroom Wall 4', 'plane025': 'Sec Bedroom Wall 4',
      'plane.778': 'Right Exterior Wall', 'plane778': 'Right Exterior Wall',
      'plane.010': 'Left Exterior Wall',  'plane010': 'Left Exterior Wall',
      'plane.011': 'Back Exterior Wall',  'plane011': 'Back Exterior Wall',
      'plane.009': 'Front Exterior Wall 1','plane009': 'Front Exterior Wall 1',
      'plane.779': 'Front Exterior Wall 2','plane779': 'Front Exterior Wall 2',
      'plane.020': 'Main Bedroom Wall 4', 'plane020': 'Main Bedroom Wall 4',
      'plane.036': 'Main Bedroom Wall 1', 'plane036': 'Main Bedroom Wall 1',
      'plane.014': 'Main Bedroom Wall 2', 'plane014': 'Main Bedroom Wall 2',
      'plane.015': 'Living Wall 1', 'plane015': 'Living Wall 1',
      'plane.777': 'Living Wall 2', 'plane777': 'Living Wall 2',
      'plane.024': 'Living Wall 3', 'plane024': 'Living Wall 3',
      'cube.032': 'Extension Roof', 'cube032': 'Extension Roof',
      'roof.001': 'Main Roof', 'roof001': 'Main Roof',
      'handle.002': 'Window Component', 'window': 'Window Unit',
      'washingmachine': 'Washing Machine', 'fridge': 'Refrigerator',
      'toilet': 'Toilet', 'sink': 'Sink', 'tub': 'Bathtub',
    };
    for (final entry in detailedMap.entries) { if (lower.contains(entry.key)) return entry.value; }
    String cleaned = rawName.replaceAll(RegExp(r'[_.]'), ' ').trim();
    cleaned = cleaned.replaceAllMapped(RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]} ${m[2]}');
    if (cleaned.isNotEmpty) cleaned = cleaned.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
    return cleaned;
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _dateStr = '${_formatDate(now)}';
      _greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';
    });
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _closePopup() {
    _popupAnim.reverse().then((_) { if(mounted) setState(() => _showRepairPopup = false); });
    js.context.callMethod('fcmReset');
  }

  void _resetSelection() {
    setState(() {
      _selectedObjectName = '';
      _cameraTarget = 'auto 1.2m auto';
      _showRepairPopup = false;
      _titleCtrl.clear();
      _detailCtrl.clear();
      _attachedImages.clear();
      _showSuccess = false;
      _showConfirmation = false;
    });
    js.context.callMethod('fcmReset');
    try { js.context.callMethod('eval', ["fcmCleanup();"]); } catch(e) {}
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 30));
    if (t != null) {
      final double m = t.hour * 60.0 + t.minute;
      final bool valid = (m >= (9*60+30) && m <= (12*60)) || (m >= (13*60) && m <= (16*60));
      if (valid) setState(() => _selectedTime = t);
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเวลาในช่วง 09:30-12:00 หรือ 13:00-16:00'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) setState(() => _attachedImages.addAll(images.map((e) => e.path)));
  }

  void _removeImage(int idx) => setState(() => _attachedImages.removeAt(idx));

  Future<void> _executeSubmission() async {
    setState(() => _isSubmitting = true);
    RepairRepository.instance.addRequest(title: _titleCtrl.text, description: _detailCtrl.text, isEmergency: _isUrgent);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() { _isSubmitting = false; _showConfirmation = false; _showSuccess = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) { _closePopup(); _resetSelection(); }
  }

  @override
  Widget build(BuildContext context) {
    final gold = DashboardTheme.primary;
    final isRepairActive = _selectedObjectName.isNotEmpty && !_showRepairPopup;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: const ValueKey('fcm_v16_full'),
              id: 'fcmHouseModel',
              src: 'assets/models/VivornFinal8.4.glb',
              alt: 'FCM House Model',
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.transparent,
              exposure: 1.2,
              shadowIntensity: 1.0,
              loading: Loading.eager,
              cameraTarget: _cameraTarget,
              cameraOrbit: _cameraOrbit,
              minCameraOrbit: 'auto 5deg 0%',
              maxCameraOrbit: 'auto 85deg auto',
              interpolationDecay: 200,
              rotationPerSecond: '6deg',
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.2, colors: [Colors.transparent, const Color(0xFF0A0A0F).withOpacity(0.6)]))))),

          // ── Header ──
          Positioned(
            top: 32, left: 40, right: 40,
            child: Row(
              children: [
                if (widget.onMenuTap != null)
                  Padding(padding: const EdgeInsets.only(right: 12), child: GestureDetector(onTap: widget.onMenuTap, child: Icon(Icons.menu_rounded, color: gold, size: 28))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_greeting,', style: GoogleFonts.outfit(color: gold.withOpacity(0.8), fontSize: 14)),
                  Text(widget.displayUser, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ]),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => js.context.callMethod('toggleRoof'),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1.5)),
                      child: Icon(Icons.roofing_rounded, color: gold, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_timeStr, style: GoogleFonts.outfit(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w200)),
                  Text(_dateStr, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                ]),
              ],
            ),
          ),

          // ── News Ticker ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _showTicker 
              ? _buildNewsTicker(gold)
              : Center(child: Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(onTap: () => setState(() => _showTicker = true), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: gold.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.campaign_rounded, color: gold, size: 14), const SizedBox(width: 8), Text('VIEW NEWS', style: GoogleFonts.outfit(color: gold, fontSize: 11, fontWeight: FontWeight.bold))]))))),
          ),

          // ── AI Chat FAB ──
          if (!_showAIChatPanel && !_showRepairPopup)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              bottom: _showTicker ? 64 : 40,
              right: isRepairActive ? 160 : 32,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showAIChatPanel = true),
                  borderRadius: BorderRadius.circular(40),
                  child: Hero(tag: 'ai_assistant_fab', child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [gold, DashboardTheme.accentAmber], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 15)]), child: Text('V', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)))),
                ),
              ),
            ),

          // ── Draggable Repair FAB & Trash ──
          if (_selectedObjectName.isNotEmpty && !_showRepairPopup)
            ValueListenableBuilder<bool>(
              valueListenable: _isRepairFabDragging,
              builder: (context, dragging, _) => Stack(children: [
                if (dragging) _buildPremiumTrashZone(context),
                _buildDraggableRepairFab(gold),
              ]),
            ),

          if (_showAIChatPanel)
            Positioned(bottom: _showTicker ? 72 : 32, right: 32, child: AIChatPanel(residentName: widget.displayUser, onClose: () => setState(() => _showAIChatPanel = false), onHistoryRequested: () { setState(() => _showAIChatPanel = false); if (widget.onHistoryRequested != null) widget.onHistoryRequested!(); })),

          // ── Repair Popup ──
          if (_showRepairPopup)
            PointerInterceptor(
              child: AnimatedBuilder(
                animation: _popupAnim,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_popupAnim.value);
                  return Stack(
                    children: [
                      Positioned.fill(child: GestureDetector(onTap: _closePopup, child: Container(color: Colors.black.withOpacity(0.5 * t)))),
                      ValueListenableBuilder<Offset>(
                        valueListenable: _popupOffset,
                        builder: (context, offset, _) => Positioned(
                          top: 100, right: 40 - (440 * (1 - t)), width: 440, bottom: 40,
                          child: Transform.translate(offset: offset, child: Opacity(opacity: t, child: _buildDraggablePopupStack(_buildRepairPanel(gold, _isDragging.value)))),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumTrashZone(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _repairFabOffset,
      builder: (context, offset, _) {
        final sh = MediaQuery.of(context).size.height;
        final sw = MediaQuery.of(context).size.width;
        final isHovered = offset.dy > sh - 220 && offset.dx > (sw/2 - 120) && offset.dx < (sw/2 + 120);
        return Positioned(
          bottom: 30, left: 0, right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isHovered ? 240 : 200, height: 100,
              decoration: BoxDecoration(color: isHovered ? Colors.redAccent.withOpacity(0.2) : Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(50), border: Border.all(color: isHovered ? Colors.redAccent : Colors.white12, width: 2), boxShadow: isHovered ? [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 30)] : []),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.delete_sweep_rounded, color: isHovered ? Colors.redAccent : Colors.white38, size: 32),
                const SizedBox(height: 8),
                Text(isHovered ? 'RELEASE TO CANCEL' : 'DRAG HERE TO CANCEL', style: GoogleFonts.shareTechMono(color: isHovered ? Colors.redAccent : Colors.white24, fontSize: 10, letterSpacing: 1.5)),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableRepairFab(Color gold) {
    return ValueListenableBuilder<Offset>(
      valueListenable: _repairFabOffset,
      builder: (context, offset, child) => Positioned(
        top: offset.dy, right: offset.dx,
        child: PointerInterceptor(
          child: GestureDetector(
            onPanStart: (_) => _isRepairFabDragging.value = true,
            onPanUpdate: (d) => _repairFabOffset.value = Offset(_repairFabOffset.value.dx - d.delta.dx, _repairFabOffset.value.dy + d.delta.dy),
            onPanEnd: (_) {
               _isRepairFabDragging.value = false;
               final sh = MediaQuery.of(context).size.height;
               final sw = MediaQuery.of(context).size.width;
               if (_repairFabOffset.value.dy > sh - 220 && _repairFabOffset.value.dx > (sw/2 - 120) && _repairFabOffset.value.dx < (sw/2 + 120)) {
                 _resetSelection();
               }
            },
            onTap: () { setState(() => _showRepairPopup = true); _popupAnim.forward(from: 0); },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: const Color(0xFF16161C), shape: BoxShape.circle, border: Border.all(color: gold.withOpacity(0.4), width: 2), boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)]),
                    child: Center(child: Icon(Icons.handyman_rounded, color: gold, size: 28)),
                  ),
                  // UNFINISHED STATE BADGE
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF16161C), width: 2.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePopupStack(Widget panel) {
    return Stack(children: [
      Positioned.fill(child: panel),
      // Hit-test only center part for dragging to keep 'X' and 'Dropdowns' interactive
      Positioned(top: 0, left: 100, right: 100, height: 80, child: GestureDetector(onPanStart: (_) => _isDragging.value = true, onPanEnd: (_) => _isDragging.value = false, onPanUpdate: (d) => _popupOffset.value += d.delta, behavior: HitTestBehavior.opaque)),
    ]);
  }

  Widget _buildRepairPanel(Color gold, bool isDragging) {
    final glowColor = _isUrgent ? Colors.redAccent : gold;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(isDragging ? 0.9 : 0.8), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white10)),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSuccess) ...[
                const Spacer(),
                Center(child: Column(children: [
                  Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(shape: BoxShape.circle, color: gold.withOpacity(0.1), border: Border.all(color: gold.withOpacity(0.3))), child: Icon(Icons.check_circle_outline_rounded, size: 80, color: gold)),
                  const SizedBox(height: 32),
                  Text('SUCCESS!', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text('Your request has been filed.', style: GoogleFonts.kanit(fontSize: 16, color: Colors.white38)),
                ])),
                const Spacer(),
              ] else if (_showConfirmation) ...[
                Expanded(child: _buildConfirmation(glowColor)),
              ] else ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('REPAIR REQUEST', style: GoogleFonts.anton(color: gold, fontSize: 24, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('SERVICE HOURS: 09:30 - 12:00 | 13:00 - 16:00', style: GoogleFonts.shareTechMono(color: gold.withOpacity(0.4), fontSize: 10, letterSpacing: 1)),
                  ]),
                  IconButton(onPressed: _closePopup, icon: const Icon(Icons.close_rounded, color: Colors.white38)),
                ]),
                const SizedBox(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel('Current Object', glowColor),
                      Text(_selectedObjectName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                      const SizedBox(height: 32),
                      _buildLabel('Category', glowColor),
                      _PremiumDropdown(selected: _selectedCategory, items: _categories, onChanged: (v) => setState(() => _selectedCategory = v)),
                      const SizedBox(height: 24),
                      _buildLabel('Subject', glowColor),
                      _PremiumInput(controller: _titleCtrl, hint: 'e.g. Water leak...', activeColor: glowColor),
                      const SizedBox(height: 24),
                      _buildLabel('Issue Details', glowColor),
                      _PremiumInput(controller: _detailCtrl, hint: 'Describe the issue...', activeColor: glowColor, maxLines: 3),
                      const SizedBox(height: 24),
                      _buildLabel('Appointment', glowColor),
                      Row(children: [
                        Expanded(child: _ScheduleTrigger(label: 'Date', value: _selectedDate == null ? null : DateFormat('MMM dd').format(_selectedDate!), icon: Icons.event, onTap: _pickDate, activeColor: glowColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _ScheduleTrigger(label: 'Time', value: _selectedTime?.format(context), icon: Icons.schedule, onTap: _pickTime, activeColor: glowColor)),
                      ]),
                      const SizedBox(height: 24),
                      _buildLabel('Photos', glowColor),
                      _PhotoPicker(imagePaths: _attachedImages, onTap: _pickImages, onRemove: _removeImage, activeColor: glowColor),
                      const SizedBox(height: 32),
                      _EmergencyToggle(value: _isUrgent, onChanged: (v) => setState(() => _isUrgent = v)),
                      const SizedBox(height: 40),
                      _SubmitAction(onTap: () {
                        if (_selectedCategory.isEmpty || _titleCtrl.text.isEmpty || _detailCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุหมวดหมู่ หัวข้อ และรายละเอียดปัญหาให้ครบถ้วน'), backgroundColor: Colors.redAccent));
                          return;
                        }
                        setState(() => _showConfirmation = true);
                      }, isUrgent: _isUrgent, gold: gold),
                      const SizedBox(height: 20),
                      Center(child: Text('SECURE ENCRYPTED FILING', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white12, letterSpacing: 2))),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 12, fontWeight: FontWeight.bold, color: c.withOpacity(0.4), letterSpacing: 2)));

  Widget _buildConfirmation(Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FINAL REVIEW', style: GoogleFonts.anton(color: Colors.white, fontSize: 24, letterSpacing: 1)),
      const SizedBox(height: 24),
      _TactileSlab(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        _ReviewRow(label: 'Category', value: _selectedCategory),
        _ReviewRow(label: 'Subject', value: _titleCtrl.text),
        _ReviewRow(label: 'Schedule', value: _selectedDate == null ? 'Not Set' : DateFormat('MMM dd').format(_selectedDate!) + ' @ ' + (_selectedTime?.format(context) ?? 'N/A')),
        _ReviewRow(label: 'Priority', value: _isUrgent ? 'EMERGENCY' : 'Regular', isRed: _isUrgent),
      ]))),
      const Spacer(),
      _isSubmitting ? const Center(child: CircularProgressIndicator()) : Row(children: [
        Expanded(child: _OverlayBtn(label: 'Back', color: Colors.white24, onTap: () => setState(() => _showConfirmation = false), isOutline: true)),
        const SizedBox(width: 12),
        Expanded(child: _OverlayBtn(label: 'Confirm Submit', color: c, onTap: _executeSubmission)),
      ]),
    ]);
  }

  Widget _buildNewsTicker(Color gold) {
    return Container(
      height: 44, decoration: BoxDecoration(color: const Color(0xFF0A0A0F).withOpacity(0.95), border: Border(top: BorderSide(color: gold.withOpacity(0.2)))),
      child: Row(children: [
        Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: [gold.withOpacity(0.2), gold.withOpacity(0.05)]), border: Border(right: BorderSide(color: gold.withOpacity(0.15)))), child: Row(children: [Icon(Icons.campaign_rounded, color: gold, size: 16), const SizedBox(width: 8), Text('NEWS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: gold, letterSpacing: 2))])),
        Expanded(child: ClipRect(child: AnimatedBuilder(animation: _tickerAnim, builder: (context, child) {
          final textStyle = GoogleFonts.outfit(fontSize: 13);
          return LayoutBuilder(builder: (context, constraints) {
            double itemWidth = 0; for (var a in _announcements) itemWidth += _measureText(a.text, textStyle) + 120;
            return Transform.translate(offset: Offset(constraints.maxWidth - (_tickerAnim.value * itemWidth), 0), child: Row(mainAxisSize: MainAxisSize.min, children: [..._announcements, ..._announcements].expand((a) => [Icon(a.icon, color: a.color, size: 14), const SizedBox(width: 8), Text(a.text, style: GoogleFonts.kanit(fontSize: 13, color: Colors.white70)), const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('●', style: TextStyle(color: Colors.white12, fontSize: 8)))]).toList()));
          });
        }))),
        Material(color: Colors.transparent, child: InkWell(onTap: () => setState(() => _showTicker = false), child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 18)))),
      ]),
    );
  }

  double _measureText(String text, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), maxLines: 1, textDirection: ui.TextDirection.ltr)..layout();
    return tp.width;
  }
}

class _Announcement { final IconData icon; final Color color; final String text; const _Announcement({required this.icon, required this.color, required this.text}); }

class _PremiumInput extends StatelessWidget {
  final TextEditingController controller; final String hint; final Color activeColor; final int maxLines;
  const _PremiumInput({required this.controller, required this.hint, required this.activeColor, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: TextField(controller: controller, maxLines: maxLines, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16), cursorColor: activeColor, decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 15), border: InputBorder.none)));
  }
}

class _PremiumDropdown extends StatelessWidget {
  final String selected; final List<Map<String, dynamic>> items; final ValueChanged<String> onChanged;
  const _PremiumDropdown({required this.selected, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: selected.isEmpty ? null : selected, isExpanded: true, dropdownColor: const Color(0xFF1A1A24), icon: const Icon(Icons.arrow_drop_down, color: Colors.white24), hint: Text('Select Category', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 15)), items: items.expand((c) => (c['items'] as List<String>).map((i) => DropdownMenuItem(value: '${c['group']}: $i', child: Text('${c['group']}: $i', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15))))).toList(), onChanged: (v) => onChanged(v ?? ''))));
  }
}

class _ScheduleTrigger extends StatelessWidget {
  final String label; final String? value; final IconData icon; final VoidCallback onTap; final Color activeColor;
  const _ScheduleTrigger({required this.label, this.value, required this.icon, required this.onTap, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: hasVal ? activeColor.withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: hasVal ? activeColor.withOpacity(0.5) : Colors.white10)), child: Column(children: [Icon(icon, color: hasVal ? activeColor : Colors.white24, size: 24), const SizedBox(height: 8), Text(label, style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.white38)), Text(value ?? 'Set', style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, fontWeight: hasVal ? FontWeight.bold : FontWeight.normal))])));
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> imagePaths; final VoidCallback onTap; final Function(int) onRemove; final Color activeColor;
  const _PhotoPicker({required this.imagePaths, required this.onTap, required this.onRemove, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(Icons.add_a_photo_rounded, color: activeColor, size: 24), const SizedBox(width: 16), Text('ATTACH PHOTOS', style: GoogleFonts.shareTechMono(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))]))),
      if (imagePaths.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: imagePaths.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, idx) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(imagePaths[idx]), width: 80, height: 80, fit: BoxFit.cover)), Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => onRemove(idx), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 10, color: Colors.white))))]))))
    ]);
  }
}

class _EmergencyToggle extends StatelessWidget {
  final bool value; final ValueChanged<bool> onChanged;
  const _EmergencyToggle({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => onChanged(!value), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: value ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: value ? Colors.redAccent : Colors.white10)), child: Row(children: [Icon(Icons.warning_amber_rounded, color: value ? Colors.redAccent : Colors.white24), const SizedBox(width: 16), Expanded(child: Text('EMERGENCY DISPATCH', style: GoogleFonts.shareTechMono(color: value ? Colors.redAccent : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))), _SimpleSwitch(value: value)])));
  }
}

class _SimpleSwitch extends StatelessWidget { final bool value; const _SimpleSwitch({required this.value}); @override Widget build(BuildContext context) { return Container(width: 40, height: 22, padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: value ? Colors.redAccent : Colors.white12, borderRadius: BorderRadius.circular(11)), child: AnimatedAlign(duration: const Duration(milliseconds: 200), alignment: value ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)))); } }

class _SubmitAction extends StatelessWidget {
  final VoidCallback onTap; final bool isUrgent; final Color gold;
  const _SubmitAction({required this.onTap, required this.isUrgent, required this.gold});
  @override
  Widget build(BuildContext context) { final c = isUrgent ? Colors.redAccent : gold; return GestureDetector(onTap: onTap, child: Container(height: 56, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 20)]), alignment: Alignment.center, child: Text(isUrgent ? 'EXECUTE EMERGENCY' : 'SUBMIT DATA', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)))); }
}

class _TactileSlab extends StatelessWidget { final Widget child; const _TactileSlab({required this.child}); @override Widget build(BuildContext context) { return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: child); } }

class _ReviewRow extends StatelessWidget {
  final String label; final String value; final bool isRed;
  const _ReviewRow({required this.label, required this.value, this.isRed = false});
  @override
  Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 13, letterSpacing: 1)), Text(value, style: GoogleFonts.outfit(color: isRed ? Colors.redAccent : Colors.white, fontSize: 15))])); }
}

class _OverlayBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap; final bool isOutline;
  const _OverlayBtn({required this.label, required this.color, required this.onTap, this.isOutline = false});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(height: 52, decoration: BoxDecoration(color: isOutline ? Colors.transparent : color, borderRadius: BorderRadius.circular(12), border: isOutline ? Border.all(color: Colors.white10) : null), alignment: Alignment.center, child: Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isOutline ? Colors.white38 : Colors.black)))); }
}
