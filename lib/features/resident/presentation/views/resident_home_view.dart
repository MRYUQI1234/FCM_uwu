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

class _ResidentHomeViewState extends State<ResidentHomeView>
    with TickerProviderStateMixin {
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
  final ValueNotifier<Offset> _repairFabOffset =
      ValueNotifier<Offset>(const Offset(40, 110));
  final ValueNotifier<bool> _isRepairFabDragging = ValueNotifier<bool>(false);

  // ── Camera State ──
  String _cameraTarget = 'auto 1.2m auto';
  String _cameraOrbit = '45deg 60deg 90%';
  final ImagePicker _picker = ImagePicker();

  static const Map<String, String> _objectCategoryMap = {
    'bathtub': 'Infrastructure: Plumbing',
    'toilet': 'Infrastructure: Plumbing',
    'water heater': 'HVAC & Appliances: Washing Machine',
    'basin': 'Infrastructure: Plumbing',
    'mirror': 'Furniture & Decor: Sofa/Carpet',
    'refrigerator': 'HVAC & Appliances: Refrigerator',
    'fridge': 'HVAC & Appliances: Refrigerator',
    'sink': 'Infrastructure: Plumbing',
    'stove': 'HVAC & Appliances: Oven',
    'oven': 'HVAC & Appliances: Oven',
    'air conditioner': 'HVAC & Appliances: Air Conditioner',
    'ac remote': 'HVAC & Appliances: Air Conditioner',
    'tv': 'HVAC & Appliances: Air Conditioner',
    'smart panel': 'Infrastructure: Lighting',
    'door': 'Infrastructure: Doors/Windows',
    'window': 'Infrastructure: Doors/Windows',
    'light': 'Infrastructure: Lighting',
    'switch': 'Infrastructure: Lighting',
    'washing machine': 'HVAC & Appliances: Washing Machine',
    'dryer': 'HVAC & Appliances: Washing Machine',
    'porch': 'Infrastructure: Doors/Windows',
    'wall': 'Structure & Build: Wall',
    'floor': 'Structure & Build: Floor',
    'ceiling': 'Structure & Build: Ceiling',
    'roof': 'Structure & Build: Roof',
    'wall tablet': 'Furniture & Decor: Wall Tablet',
    'cube023': 'Furniture & Decor: Wall Tablet',
    'condenser': 'HVAC & Appliances: Air Conditioner',
    'sofa': 'Furniture & Decor: Sofa/Carpet',
    'couch': 'Furniture & Decor: Sofa/Carpet',
    'carpet': 'Furniture & Decor: Sofa/Carpet',
    'rug': 'Furniture & Decor: Sofa/Carpet',
    'closet': 'Furniture & Decor: Closet/Cabinet',
    'cabinet': 'Furniture & Decor: Closet/Cabinet',
    'nightstand': 'Furniture & Decor: Bed/Table',
    'downpipe': 'Infrastructure: Plumbing',
    'gutter': 'Infrastructure: Plumbing',
  };

  final _categories = [
    {
      'group': 'HVAC & Appliances',
      'items': ['Air Conditioner', 'Refrigerator', 'Oven', 'Washing Machine']
    },
    {
      'group': 'Infrastructure',
      'items': ['Doors/Windows', 'Lighting', 'Plumbing']
    },
    {
      'group': 'Structure & Build',
      'items': ['Wall', 'Floor', 'Ceiling', 'Roof']
    },
    {
      'group': 'Furniture & Decor',
      'items': ['Sofa/Carpet', 'Closet/Cabinet', 'Bed/Table', 'Wall Tablet']
    },
  ];

  final List<_Announcement> _announcements = const [
    _Announcement(
        icon: Icons.water_drop_rounded,
        color: Color(0xFF60A5FA),
        text: 'Water Tank Cleaning — Water off 09:00 – 12:00 (Feb 15)'),
    _Announcement(
        icon: Icons.bug_report_rounded,
        color: Color(0xFFFBBF24),
        text: 'Mosquito Spraying — Close all windows & doors (Feb 20)'),
    _Announcement(
        icon: Icons.groups_rounded,
        color: Color(0xFF34D399),
        text: 'Annual General Meeting — Clubhouse, 6:00 PM (Feb 25)'),
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
    _tickerAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat();
    _popupAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
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
      js.context['onHomeObjectClicked'] = (dynamic name) {
        if (mounted) _handleObjectClick(name);
      };

      js.context['fcmDebugLog'] = (dynamic msg) {
        print("★★★ FCM_DEBUG_HOME: $msg ★★★");
      };

      js.context.callMethod('eval', [
        r"""
        (function() {
          // ── V15.0 — Precision Selection Rewrite (NDC Ray + Möller-Trumbore + Overlay) ──

          const getScene = (mv) => {
             const syms = Object.getOwnPropertySymbols(mv);
             for (const s of syms) {
                const v = mv[s];
                if (v && (v.type === 'Scene' || v.scene?.type === 'Scene')) return v.scene || v;
             }
             return null;
          };

          // ── Safe overlay cleanup ──
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

          // ── Camera Helpers ──
          window.fcmFocus = function(target, zoomFactor) {
              const mv = document.getElementById('fcmHouseModel');
              if (mv) {
                  console.log('[FCM] focus target ->', target);
                  if (target) mv.cameraTarget = target;
                  
                  // Zoom without rotating: Get current orbit, keep theta/phi, change ONLY radius
                  const currentOrbit = mv.getCameraOrbit(); // {theta, phi, radius}
                  if (currentOrbit && zoomFactor) {
                      const newRadius = currentOrbit.radius * zoomFactor;
                      mv.cameraOrbit = `${currentOrbit.theta}rad ${currentOrbit.phi}rad ${newRadius}m`;
                  }
              }
          };

          window.fcmReset = function() {
              const mv = document.getElementById('fcmHouseModel');
              console.log('[FCM] RESET CALL:', { mvFound: !!mv });
              if (mv) {
                  mv.cameraTarget = 'auto 1.2m auto';
                  mv.cameraOrbit = '45deg 60deg 90%';
              }
          };

          // ── Create highlight material from reference ──
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
              } catch(_) {
                  try {
                      const m = refMat.clone();
                      if (m.color) m.color.setHex(0xff7700);
                      m.transparent = true; m.opacity = 0.75; m.depthWrite = false;
                      return m;
                  } catch(__) { return null; }
              }
          }

          // ── Create overlay for one mesh ──
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
                  ov.matrixAutoUpdate = true;
                  if (mesh.parent) { mesh.parent.add(ov); return ov; }
              } catch(e) { console.warn('[FCM] overlay err:', e); }
              return null;
          }

          // ── Roof toggle ──
          window.toggleRoof = function() {
              if (window._fcmRoofVis === undefined) window._fcmRoofVis = true;
              window._fcmRoofVis = !window._fcmRoofVis;
              const state = window._fcmRoofVis;
              const isProtected = n => {
                  let c = n; while(c) { const nm=(c.name||'').toLowerCase();
                      if(nm.includes('couch')||nm.includes('sofa')||nm.includes('door')||nm.includes('gate')||nm.includes('window'))return true;
                      c=c.parent; } return false;
              };
              document.querySelectorAll('model-viewer').forEach(mv => {
                  const scene = getScene(mv); if(!scene)return;
                  scene.traverse(node => {
                      if(isProtected(node))return;
                      const l=(node.name||'').toLowerCase().trim();
                      if(l.includes('cube032')||l.includes('cube_032')||l.includes('cube.032')||l.includes('roof')) node.visible=state;
                  });
              });
          };

          window.hideBadNodes = function() {
              document.querySelectorAll('model-viewer').forEach(mv => {
                  const scene = getScene(mv);
                  if (scene) scene.traverse(n => { 
                      const nm = (n.name||'').toLowerCase();
                      if(nm === 'door001' || nm.includes('tapis')) n.visible=false; 
                  });
              });
          };

          // ── Unproject helper: NDC → world space ──
          function fcmUnproject(nx, ny, nz, cam) {
              const pi = cam.projectionMatrixInverse.elements;
              const cw = cam.matrixWorld.elements;
              // NDC → camera space
              const w = pi[3]*nx + pi[7]*ny + pi[11]*nz + pi[15];
              const cx = (pi[0]*nx + pi[4]*ny + pi[8]*nz + pi[12]) / w;
              const cy = (pi[1]*nx + pi[5]*ny + pi[9]*nz + pi[13]) / w;
              const cz = (pi[2]*nx + pi[6]*ny + pi[10]*nz + pi[14]) / w;
              // camera space → world space
              return {
                  x: cw[0]*cx + cw[4]*cy + cw[8]*cz + cw[12],
                  y: cw[1]*cx + cw[5]*cy + cw[9]*cz + cw[13],
                  z: cw[2]*cx + cw[6]*cy + cw[10]*cz + cw[14]
              };
          }

          // ── Main selection ──
          window.setupFcmSelection = function() {
              document.querySelectorAll('model-viewer').forEach(mv => {
                  if (mv._fcmV15) return;
                  mv._fcmV15 = true;

                  mv.addEventListener('click', (event) => {
                      try {
                          const materialObj = mv.materialFromPoint(event.clientX, event.clientY);
                          const hitData = mv.positionAndNormalFromPoint(event.clientX, event.clientY);

                          // Always clean previous
                          fcmCleanup();

                          if (!materialObj || !hitData || !hitData.position) {
                              if (window.onHomeObjectClicked) window.onHomeObjectClicked('');
                              return;
                          }

                          const scene = getScene(mv);
                          if (!scene) return;

                          // Get Three.js camera
                          let camera = null;
                          Object.getOwnPropertySymbols(mv).forEach(s => {
                              if (mv[s] && mv[s].camera) camera = mv[s].camera;
                          });
                          if (!camera) return;

                          // ★ Proper NDC ray from screen coordinates
                          const rect = mv.getBoundingClientRect();
                          const ndcX = ((event.clientX - rect.left) / rect.width) * 2 - 1;
                          const ndcY = -((event.clientY - rect.top) / rect.height) * 2 + 1;

                          camera.updateMatrixWorld(true);

                          const nearPt = fcmUnproject(ndcX, ndcY, -1, camera);
                          const farPt  = fcmUnproject(ndcX, ndcY,  1, camera);
                          const rayOrigin = camera.position;
                          let rdx = farPt.x - nearPt.x;
                          let rdy = farPt.y - nearPt.y;
                          let rdz = farPt.z - nearPt.z;
                          const rLen = Math.sqrt(rdx*rdx + rdy*rdy + rdz*rdz);
                          if (rLen < 1e-10) return;
                          rdx /= rLen; rdy /= rLen; rdz /= rLen;


                          let targetMesh = null;
                          let closestDist = Infinity;

                          // ★ Möller-Trumbore: test ALL visible meshes (no material filter)
                          scene.traverse(node => {
                              if (!node.isMesh || !node.material || !node.geometry) return;
                              // Check entire parent chain — if ANY ancestor is hidden, skip
                              let anc = node; while(anc) { if (!anc.visible) return; anc = anc.parent; }
                              if ((node.name||'').toLowerCase() === 'walls') return;

                              node.updateMatrixWorld(true);
                              const inv = node.matrixWorld.clone().invert();
                              const el = inv.elements;

                              // Ray origin → local space
                              const loX = rayOrigin.x*el[0]+rayOrigin.y*el[4]+rayOrigin.z*el[8]+el[12];
                              const loY = rayOrigin.x*el[1]+rayOrigin.y*el[5]+rayOrigin.z*el[9]+el[13];
                              const loZ = rayOrigin.x*el[2]+rayOrigin.y*el[6]+rayOrigin.z*el[10]+el[14];
                              // Ray direction → local space (no translation)
                              const ldx = rdx*el[0]+rdy*el[4]+rdz*el[8];
                              const ldy = rdx*el[1]+rdy*el[5]+rdz*el[9];
                              const ldz = rdx*el[2]+rdy*el[6]+rdz*el[10];

                              const pos = node.geometry.attributes.position;
                              if (!pos) return;
                              const arr = pos.array;
                              const idx = node.geometry.index;
                              let minT = Infinity;

                              const tri = (i0,i1,i2) => {
                                  const v0x=arr[i0*3],v0y=arr[i0*3+1],v0z=arr[i0*3+2];
                                  const v1x=arr[i1*3],v1y=arr[i1*3+1],v1z=arr[i1*3+2];
                                  const v2x=arr[i2*3],v2y=arr[i2*3+1],v2z=arr[i2*3+2];
                                  const e1x=v1x-v0x,e1y=v1y-v0y,e1z=v1z-v0z;
                                  const e2x=v2x-v0x,e2y=v2y-v0y,e2z=v2z-v0z;
                                  const hx=ldy*e2z-ldz*e2y,hy=ldz*e2x-ldx*e2z,hz=ldx*e2y-ldy*e2x;
                                  const a=e1x*hx+e1y*hy+e1z*hz;
                                  if(a>-1e-6&&a<1e-6)return;
                                  const f=1.0/a;
                                  const sx=loX-v0x,sy=loY-v0y,sz=loZ-v0z;
                                  const u=f*(sx*hx+sy*hy+sz*hz);
                                  if(u<0||u>1)return;
                                  const qx=sy*e1z-sz*e1y,qy=sz*e1x-sx*e1z,qz=sx*e1y-sy*e1x;
                                  const v=f*(ldx*qx+ldy*qy+ldz*qz);
                                  if(v<0||u+v>1)return;
                                  const t=f*(e2x*qx+e2y*qy+e2z*qz);
                                  if(t>1e-6&&t<minT)minT=t;
                              };

                              if(idx){const a=idx.array;for(let i=0;i<a.length;i+=3)tri(a[i],a[i+1],a[i+2]);}
                              else{for(let i=0;i<arr.length/3;i+=3)tri(i,i+1,i+2);}

                              if (minT < Infinity && minT < closestDist) {
                                  closestDist = minT;
                                  targetMesh = node;
                              }
                          });

                          if (!targetMesh) {
                              if (window.onHomeObjectClicked) window.onHomeObjectClicked('');
                              return;
                          }

                          // Group logic — Blender splits multi-material objects into child meshes
                          let bestName = targetMesh.name || 'Mesh';
                          let bestNode = targetMesh;
                          const hierarchySkip = ['scene', 'target', 'root', 'model', 'house'];
                          const selectionIgnore = ['wall', 'floor', 'ceiling', 'bed', 'vase', 'plant', 'table', 'carpet', 'rug', 'curtain', 'blind', 'glass', 'stone', 'louvers', 'pillar', 'beam', 'brick', 'stair', 'grass', 'ground', 'sky', 'fence'];
                          const interactive = ['ac', 'conditioner', 'toilet', 'sink', 'bathtub', 'stove', 'fridge', 'refrigerator', 'panel', 'door', 'window', 'light', 'fixture', 'switch', 'washing', 'dryer', 'smart', 'pump', 'condenser', 'lock', 'handle', 'faucet', 'shower', 'cabinet', 'closet', 'sensor', 'intercom', 'unit'];
                          const propIds = ['plane046', 'plane045', 'plane043', 'cube015', 'cube046', 'cube047'];
                          
                          let curr = targetMesh.parent;
                          while (curr && curr.type !== 'Scene') {
                              if (curr.name) {
                                  const cName = curr.name.toLowerCase();
                                  // Stop walking up if we hit a structural/scene node
                                  if (hierarchySkip.some(s => cName.includes(s))) break;
                                  
                                  bestName = curr.name;
                                  bestNode = curr;
                              }
                              curr = curr.parent;
                          }

                           // ★ Final selectable check (JS side)
                           const checkName = (bestName || '').toLowerCase();
                           const isInteractive = interactive.some(s => checkName.includes(s));
                           const shouldIgnore = selectionIgnore.some(s => checkName.includes(s));
                           
                           // If it's not explicitly interactive AND (matches an ignore keyword OR is a specific prop ID), block it
                           if ((!isInteractive && shouldIgnore) || propIds.some(id => checkName.includes(id))) {
                               console.log('[FCM] Ignoring non-selectable highlight:', bestName);
                               // No highlight, no popup, no camera move
                               if (window.onHomeObjectClicked) window.onHomeObjectClicked('');
                               return;
                           }

                           // ★ Overlay highlight (no material bleed)
                           window._fcmOverlays = [];
                           if (bestNode.isMesh) {
                               const o = fcmOverlay(bestNode);
                               if (o) window._fcmOverlays.push(o);
                           } else {
                               bestNode.traverse(ch => {
                                   if (ch.isMesh && ch.visible) {
                                       const o = fcmOverlay(ch);
                                       if (o) window._fcmOverlays.push(o);
                                   }
                               });
                           }

                          // Hierarchy dump
                          let path = targetMesh.name;
                          let p = targetMesh.parent; let d = 0;
                          while(p && p.type !== 'Scene' && d < 4) { path = (p.name||p.type)+'>'+path; p=p.parent; d++; }

                          if (window.onHomeObjectClicked) {
                              const pos = hitData.position;
                              const focus = pos.x.toFixed(3) + 'm ' + pos.y.toFixed(3) + 'm ' + pos.z.toFixed(3) + 'm';
                              console.log('[FCM] CLICK HIT EVENT:', { 
                                  mesh: targetMesh.name, 
                                  node: bestName,
                                  hitPos: focus,
                                  worldPos: pos
                              });
                              
                              window.onHomeObjectClicked(JSON.stringify({
                                  name: bestName + ' [' + path + ']',
                                  focus: focus
                              }));
                          }
                          console.log('[FCM] เลือก:', bestName, '| dist:', closestDist.toFixed(4));

                      } catch (e) {
                          console.error('[FCM] Selection Error:', e);
                      }
                  });
              });
          };

          const poll = setInterval(() => {
              if (document.querySelector('model-viewer')) {
                  window.setupFcmSelection();
                  window.hideBadNodes();
                  clearInterval(poll);
              }
          }, 500);
        })();
        """
      ]);
    } catch (e) {
      print("FCM JS Init Error: $e");
    }
  }

  void _handleObjectClick(dynamic raw) {
    try {
      String name = '';
      String focusPos = '';

      if (raw is String && raw.startsWith('{')) {
        final data = jsonDecode(raw);
        name = data['name'] ?? '';
        focusPos = data['focus'] ?? '';
      } else {
        name = raw.toString();
      }

      if (name.isEmpty) return;

      String shortName = name.split(' [').first;
      final displayName = _formatObjectName(shortName);

      setState(() {
        _selectedObjectName = displayName;
        _cameraTarget = focusPos;
        _repairFabOffset.value = const Offset(40, 110);
        _titleCtrl.text = displayName;

        // Auto-select category (Robust matching)
        _selectedCategory = '';
        final lowerDisplay = displayName.toLowerCase();

        _objectCategoryMap.forEach((key, value) {
          if (lowerDisplay.contains(key)) _selectedCategory = value;
        });

        // Final fallback if the above soft-match fails, try exact group items
        if (_selectedCategory.isEmpty) {
          for (final cat in _categories) {
            final group = cat['group'] as String;
            final items = cat['items'] as List<String>;
            for (final item in items) {
              if (lowerDisplay.contains(item.toLowerCase())) {
                _selectedCategory = '$group: $item';
                break;
              }
            }
            if (_selectedCategory.isNotEmpty) break;
          }
        }

        _showSuccess = false;
        _showConfirmation = false;
        _showRepairPopup = true;
      });
      _popupAnim.forward(from: 0.0);
      if (focusPos.isNotEmpty) {
        js.context.callMethod('fcmFocus', [_cameraTarget, 0.7]);
      }
    } catch (e) {}
  }

  String _formatObjectName(String rawName) {
    final lower = rawName.toLowerCase();

    if (lower == 'plane') return 'MainbedroomWall3';
    if (lower == 'floor' || lower == 'floors') return 'Laundry Floor';

    final Map<String, String> detailedMap = {
      // Structure & Floors
      'plane.008': 'SecBedroomWall1',
      'plane008': 'SecBedroomWall1',
      'plane.012': 'SecBedroomWall2',
      'plane012': 'SecBedroomWall2',
      'plane.007': 'SecBedroomWall3',
      'plane007': 'SecBedroomWall3',
      'plane.025': 'SecbedroomWall4',
      'plane025': 'SecbedroomWall4',
      'plane.778': 'RightExteriorWall',
      'plane778': 'RightExteriorWall',
      'plane.010': 'Left Exterior Wall',
      'plane010': 'Left Exterior Wall',
      'plane.011': 'Back Exterior Wall',
      'plane011': 'Back Exterior Wall',
      'plane.009': 'Front Exterior Wall 1',
      'plane009': 'Front Exterior Wall 1',
      'plane.779': 'Front Exterior Wall 2',
      'plane779': 'Front Exterior Wall 2',
      'plane.052': 'Inner Front Wall (Porch)',
      'plane052': 'Inner Front Wall (Porch)',
      'plane.020': 'MainbedroomWall4',
      'plane020': 'MainbedroomWall4',
      'plane.036': 'MainbedroomWall1',
      'plane036': 'MainbedroomWall1',
      'plane.014': 'MainbedroomWall2',
      'plane014': 'MainbedroomWall2',
      'plane.017': 'MainbedroomWall5',
      'plane017': 'MainbedroomWall5',
      'plane.019': 'MainbedroomWall6',
      'plane019': 'MainbedroomWall6',
      'plane.001': 'LivingSwitch',
      'plane001': 'LivingSwitch',
      'plane.002': 'BathroomSwitch1',
      'plane002': 'BathroomSwitch1',
      'plane.003': 'KitchenSwitch',
      'plane003': 'KitchenSwitch',
      'plane.004': 'MainbedroomSwitch',
      'plane004': 'MainbedroomSwitch',
      'plane.049': 'SecbedroomSwitch',
      'plane049': 'SecbedroomSwitch',
      'plane.015': 'LivingWall1',
      'plane015': 'LivingWall1',
      'plane.777': 'LivingWall2',
      'plane777': 'LivingWall2',
      'plane.024': 'LivingWall3',
      'plane024': 'LivingWall3',
      'plane.018': 'LivingWall4',
      'plane018': 'LivingWall4',
      'plane.037': 'LivingWall5',
      'plane037': 'LivingWall5',
      'plane.021': 'KitchenWall1',
      'plane021': 'KitchenWall1',
      'plane.023': 'KitchenWall2',
      'plane023': 'KitchenWall2',
      'plane.027': 'KitchenWall3',
      'plane027': 'KitchenWall3',
      'plane.038': 'KitchenWall4',
      'plane038': 'KitchenWall4',
      'plane.041': '1BathroomWall1',
      'plane041': '1BathroomWall1',
      'plane.040': '1BathroomWall2',
      'plane040': '1BathroomWall2',
      'plane.042': '1BathroomWall3',
      'plane042': '1BathroomWall3',
      'plane.013': '1BathroomWall4',
      'plane013': '1BathroomWall4',
      'plane.016': '1BathroomWall5',
      'plane016': '1BathroomWall5',
      'plane.022': '1BathroomWall6',
      'plane022': '1BathroomWall6',
      'plane.039': 'LivingWall6',
      'plane039': 'LivingWall6',
      'cube.032': 'Extension Roof',
      'cube032': 'Extension Roof',
      'cube.022': 'RightSideExtension',
      'cube022': 'RightSideExtension',
      'house.001': 'Stone Veneer Column',
      'house001': 'Stone Veneer Column',
      'roof.001': 'Main Roof',
      'roof001': 'Main Roof',
      'cube.016': 'Wooden Louvers1',
      'cube016': 'Wooden Louvers1',
      'cube.018': 'Wooden Louvers2',
      'cube018': 'Wooden Louvers2',
      'трубаводостcylinder': 'Rain Water Downpipe',
      'floors.001': 'Living Room Floor',
      'floors001': 'Living Room Floor',
      'floors.002': 'MainBedroom Floor',
      'floors002': 'MainBedroom Floor',
      'floors.009': 'SecBedroom Floor',
      'floors009': 'SecBedroom Floor',
      'floors.003': 'Kitchen Floor',
      'floors003': 'Kitchen Floor',
      'floors.004': 'Bathroom Floor1',
      'floors004': 'Bathroom Floor1',
      'floors.005': 'SecBedroom Floor',
      'floors005': 'SecBedroom Floor',
      'floors.006': 'Bathroom Floor2',
      'floors006': 'Bathroom Floor2',
      'strike plate 010.001': 'Smart Door Lock',
      'strike plate 010001': 'Smart Door Lock',
      'handle.002': 'RightWindow1',
      'handle002': 'RightWindow1',
      'windowr.002': 'RightWindow3',
      'windowr002': 'RightWindow3',
      'windowframe.007': 'RearWindow1',
      'windowframe007': 'RearWindow1',
      'windowl.006': 'RearWindow2',
      'windowl006': 'RearWindow2',
      'handle.009': 'LeftWindow1',
      'handle009': 'LeftWindow1',
      'windowr.005': 'LeftWindow2',
      'windowr005': 'LeftWindow2',
      'windowr.003': 'FrontWindow',
      'windowr003': 'FrontWindow',
      'handle_front.010': 'SecBedroomDoor',
      'handle_front010': 'SecBedroomDoor',
      'handle_front.001': 'BathroomDoor1',
      'handle_front001': 'BathroomDoor1',
      'handle_back.002': 'MainBedroomDoor',
      'handle_back002': 'MainBedroomDoor',
      'handle_front.006': 'BathroomDoor2',
      'handle_front006': 'BathroomDoor2',
      'door.006': 'LaundryDoor',
      'door006': 'LaundryDoor',
      'handle': 'RightWindow2',
      'direction.001': 'Air Conditioner1',
      'direction001': 'Air Conditioner1',
      'direction.002': 'Air Conditioner2',
      'direction002': 'Air Conditioner2',
      'air conditioner split midea': 'Air Conditioner (Indoor)',
      'air conditioner outdoor unit': 'Air Conditioner (Outdoor)',
      'remote for air conditioning unit': 'AC Remote',
      'digital door lock': 'Digital Door Lock',
      'light switch a': 'Light Switch',
      'qbic': 'Smart Panel PC',
      'washingmachine': 'Washing Machine',
      'dryer': 'Dryer',
      'fridge': 'Refrigerator',
      'refrigerator': 'Refrigerator',
      'lampbase.002': 'LivingLight',
      'lampbase002': 'LivingLight',
      'lampbase.007': 'KitchenLight',
      'lampbase007': 'KitchenLight',
      'lampbase.003': 'MainBedroomLight',
      'lampbase003': 'MainBedroomLight',
      'lampbase.001': 'SecBedroomLight',
      'lampbase001': 'SecBedroomLight',
      'double_spot_light.002': 'LaundryLight',
      'double_spot_light002': 'LaundryLight',
      'double_spot_light.001': 'BathroomLight1',
      'double_spot_light001': 'BathroomLight1',
      'double_spot_light.004': 'BathroomLight2',
      'double_spot_light004': 'BathroomLight2',
      'spot light.001': 'BathroomLight1',
      'spot light001': 'BathroomLight1',
      'spot light.002': 'LaundryLight',
      'spot light002': 'LaundryLight',
      'spot light.004': 'BathroomLight2',
      'spot light004': 'BathroomLight2',
      'cube.024': 'Condenser1',
      'cube024': 'Condenser1',
      '円柱.003': 'Condenser2',
      '円柱003': 'Condenser2',
      'modern ceiling light 01': 'Ceiling Light',
      'double spot light': 'Spot Light',
      'bollard lighting': 'Bollard Garden Light',
      'cube.017': 'Outdoor Light',
      'cube017': 'Outdoor Light',
      'couchdouble': 'Sofa (Living)',
      'coffeetable': 'Coffee Table',
      'designer carpet': 'Carpet/Rug',
      'closetr': 'Bedroom Closet',
      'closettv': 'TV Cabinet',
      'nightstand': 'Nightstand',
      'floorcabinet001': 'Floor Cabinet 1',
      'floorcabinet.001': 'Floor Cabinet 1',
      'floorcabinet002': 'Floor Cabinet 2',
      'floorcabinet.002': 'Floor Cabinet 2',
      'floorcabinet003': 'Floor Cabinet 3',
      'floorcabinet.003': 'Floor Cabinet 3',
      'floorcabinet': 'Floor Cabinet',
      'wallcabinet2': 'Wall Cabinet 1',
      'wallcabinet.002': 'Wall Cabinet 1',
      'wallcabinet4002': 'Wall Cabinet 2',
      'wallcabinet.4002': 'Wall Cabinet 2',
      'wallcabinet4001': 'Wall Cabinet 3',
      'wallcabinet.4001': 'Wall Cabinet 3',
      'wallcabinet4': 'Wall Cabinet 4',
      'wallcabinet.004': 'Wall Cabinet 4',
      'wallcabinet': 'Wall Cabinet',
      'kitchensinkl': 'Kitchen Sink',
      'cube023': 'Wall Tablet',
      'stover': 'Kitchen Stove',
      'sink001': 'Bathroom Sink2',
      'sink.001': 'Bathroom Sink2',
      'sink': 'Bathroom Sink1',
      'toilet001': 'Toilet2',
      'toilet.001': 'Toilet2',
      'toilet2': 'Toilet2',
      'toilet': 'Toilet1',
      'tub2': 'Bathtub2',
      'tub.002': 'Bathtub2',
      'tub': 'Bathtub1',
      'mirror': 'Bathroom Mirror',
      'basin': 'Bathroom Basin',
    };

    for (final entry in detailedMap.entries) {
      if (lower.contains(entry.key)) {
        String base = entry.value;
        if (rawName.contains('.')) {
          final suffix = rawName.split('.').last;
          if (RegExp(r'^\d+$').hasMatch(suffix)) {
            return '$base ${int.parse(suffix)}';
          }
        }
        return base;
      }
    }

    String cleaned = rawName.replaceAll(RegExp(r'[_.]'), ' ').trim();
    cleaned = cleaned.replaceAll(
        RegExp(r'Modern Ceiling Light 01', caseSensitive: false),
        'Ceiling Light');
    cleaned = cleaned.replaceAll(
        RegExp(r'Double spot light', caseSensitive: false), 'Spot Light');
    cleaned = cleaned.replaceAllMapped(
        RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]} ${m[2]}');
    cleaned =
        cleaned.replaceAll(RegExp(r'plane', caseSensitive: false), 'Wall');
    if (lower.startsWith('light') ||
        lower.startsWith('point') ||
        lower.startsWith('spot')) {
      cleaned = cleaned.replaceAll(
          RegExp(r'light|point|spot', caseSensitive: false), 'Light Fixture');
    }

    if (cleaned.isNotEmpty) {
      cleaned = cleaned.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    return cleaned;
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _dateStr = '${_formatDate(now)}';
      _greeting = now.hour < 12
          ? 'Good Morning'
          : now.hour < 17
              ? 'Good Afternoon'
              : 'Good Evening';
    });
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _closePopup() {
    _popupAnim.reverse().then((_) {
      if (mounted) setState(() => _showRepairPopup = false);
    });
    // Removed fcmReset to maintain camera focus
  }

  void _resetSelection() {
    setState(() {
      _selectedObjectName = '';
      // Removed auto 1.2m auto to keep last position
      _showRepairPopup = false;
      _titleCtrl.clear();
      _detailCtrl.clear();
      _attachedImages.clear();
      _showSuccess = false;
      _showConfirmation = false;
    });
    // Removed fcmReset call
    try {
      js.context.callMethod('eval', ["fcmCleanup();"]);
    } catch (e) {}
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)));
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 9, minute: 30));
    if (t != null) {
      final double m = t.hour * 60.0 + t.minute;
      final bool valid = (m >= (9 * 60 + 30) && m <= (12 * 60)) ||
          (m >= (13 * 60) && m <= (16 * 60));
      if (valid)
        setState(() => _selectedTime = t);
      else
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('กรุณาเลือกเวลาในช่วง 09:30-12:00 หรือ 13:00-16:00'),
            backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty)
      setState(() => _attachedImages.addAll(images.map((e) => e.path)));
  }

  void _removeImage(int idx) => setState(() => _attachedImages.removeAt(idx));

  Future<void> _executeSubmission() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.dark(),
        child: AlertDialog(
          backgroundColor: const Color(0xFF16161C),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10)),
          title: Text('ยืนยันการส่งข้อมูล?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text(
              'คุณตรวจสอบข้อมูลทั้งหมดแล้ว และพร้อมที่จะส่งเพื่อดำเนินการซ่อมแซมใช่หรือไม่?',
              style: GoogleFonts.kanit(color: Colors.white70)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('ยกเลิก',
                  style: GoogleFonts.kanit(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isUrgent ? Colors.redAccent : DashboardTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('ยืนยัน',
                  style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    RepairRepository.instance.addRequest(
      title: _titleCtrl.text.isEmpty ? _selectedObjectName : _titleCtrl.text,
      description: _detailCtrl.text,
      isEmergency: _isUrgent,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTime,
      imagePaths: _attachedImages,
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showConfirmation = false;
        _showSuccess = true;
      });
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _closePopup();
      _resetSelection();
      widget.onHistoryRequested?.call();
    }
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
              autoRotate: false,
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
          Positioned.fill(
              child: IgnorePointer(
                  child: Container(
                      decoration: BoxDecoration(
                          gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.2,
                              colors: [
                Colors.transparent,
                const Color(0xFF0A0A0F).withOpacity(0.6)
              ]))))),

          // ── Header ──
          Positioned(
            top: 32,
            left: 40,
            right: 40,
            child: Row(
              children: [
                if (widget.onMenuTap != null)
                  Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                          onTap: widget.onMenuTap,
                          child:
                              Icon(Icons.menu_rounded, color: gold, size: 28))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$_greeting,',
                      style: GoogleFonts.outfit(
                          color: gold.withOpacity(0.8), fontSize: 14)),
                  Text(widget.displayUser,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ]),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => js.context.callMethod('toggleRoof'),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white24, width: 1.5)),
                      child: Icon(Icons.roofing_rounded, color: gold, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_timeStr,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w200)),
                  Text(_dateStr,
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 13)),
                ]),
              ],
            ),
          ),

          // ── News Ticker ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _showTicker
                ? _buildNewsTicker(gold)
                : Center(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                            onTap: () => setState(() => _showTicker = true),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: gold.withOpacity(0.3))),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.campaign_rounded,
                                          color: gold, size: 14),
                                      const SizedBox(width: 8),
                                      Text('VIEW NEWS',
                                          style: GoogleFonts.outfit(
                                              color: gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold))
                                    ]))))),
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
                  child: Hero(
                    tag: 'ai_assistant_fab',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gold, DashboardTheme.accentAmber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                              color: gold.withOpacity(0.3), blurRadius: 15)
                        ],
                      ),
                      child: Text(
                        TranslationService.instance.t('v_chat_with_ai'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
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
            Positioned(
                bottom: _showTicker ? 72 : 32,
                right: 32,
                child: AIChatPanel(
                    residentName: widget.displayUser,
                    onClose: () => setState(() => _showAIChatPanel = false),
                    onHistoryRequested: () {
                      setState(() => _showAIChatPanel = false);
                      if (widget.onHistoryRequested != null)
                        widget.onHistoryRequested!();
                    })),

          // ── Repair Popup ──
          if (_showRepairPopup)
            PointerInterceptor(
              child: AnimatedBuilder(
                animation: _popupAnim,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_popupAnim.value);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return Stack(
                    children: [
                      Positioned.fill(
                          child: GestureDetector(
                              onTap: _closePopup,
                              child: Container(
                                  color: Colors.black.withOpacity(0.6 * t)))),
                      if (isMobile)
                        // ── Mobile: centered, no drag ──
                        Positioned.fill(
                          child: Center(
                            child: Opacity(
                              opacity: t,
                              child: Transform.scale(
                                scale: 0.9 + 0.1 * t,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 40),
                                  child: _buildPopupStack(
                                      _buildRepairPanel(gold, false)),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        // ── Desktop: right panel (original) ──
                        ValueListenableBuilder<Offset>(
                          valueListenable: _popupOffset,
                          builder: (context, offset, _) => Positioned(
                            top: 100,
                            right: 40 - (440 * (1 - t)),
                            width: 440,
                            bottom: 40,
                            child: Transform.translate(
                                offset: offset,
                                child: Opacity(
                                    opacity: t,
                                    child: _buildDraggablePopupStack(
                                        _buildRepairPanel(
                                            gold, _isDragging.value)))),
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
        final isHovered = offset.dy > sh - 220 &&
            offset.dx > (sw / 2 - 120) &&
            offset.dx < (sw / 2 + 120);
        return Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isHovered ? 240 : 200,
              height: 100,
              decoration: BoxDecoration(
                  color: isHovered
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: isHovered ? Colors.redAccent : Colors.white12,
                      width: 2),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                              color: Colors.redAccent.withOpacity(0.2),
                              blurRadius: 30)
                        ]
                      : []),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: isHovered ? Colors.redAccent : Colors.white38,
                        size: 32),
                    const SizedBox(height: 8),
                    Text(
                        isHovered ? 'RELEASE TO CANCEL' : 'DRAG HERE TO CANCEL',
                        style: GoogleFonts.shareTechMono(
                            color:
                                isHovered ? Colors.redAccent : Colors.white24,
                            fontSize: 10,
                            letterSpacing: 1.5)),
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
        top: offset.dy,
        right: offset.dx,
        child: PointerInterceptor(
          child: GestureDetector(
            onPanStart: (_) => _isRepairFabDragging.value = true,
            onPanUpdate: (d) => _repairFabOffset.value = Offset(
                _repairFabOffset.value.dx - d.delta.dx,
                _repairFabOffset.value.dy + d.delta.dy),
            onPanEnd: (_) {
              _isRepairFabDragging.value = false;
              final sh = MediaQuery.of(context).size.height;
              final sw = MediaQuery.of(context).size.width;
              if (_repairFabOffset.value.dy > sh - 220 &&
                  _repairFabOffset.value.dx > (sw / 2 - 120) &&
                  _repairFabOffset.value.dx < (sw / 2 + 120)) {
                _resetSelection();
              }
            },
            onTap: () {
              setState(() => _showRepairPopup = true);
              _popupAnim.forward(from: 0);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: const Color(0xFF16161C),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: gold.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black, blurRadius: 20)
                        ]),
                    child: Center(
                        child: Icon(Icons.handyman_rounded,
                            color: gold, size: 28)),
                  ),
                  // UNFINISHED STATE BADGE
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF16161C), width: 2.5)),
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

  /// Non-draggable popup wrapper (mobile)
  Widget _buildPopupStack(Widget panel) {
    return Stack(children: [
      Positioned.fill(child: panel),
    ]);
  }

  Widget _buildDraggablePopupStack(Widget panel) {
    return Stack(children: [
      Positioned.fill(child: panel),
      // Hit-test only center part for dragging to keep 'X' and 'Dropdowns' interactive
      Positioned(
          top: 0,
          left: 100,
          right: 100,
          height: 80,
          child: GestureDetector(
              onPanStart: (_) => _isDragging.value = true,
              onPanEnd: (_) => _isDragging.value = false,
              onPanUpdate: (d) => _popupOffset.value += d.delta,
              behavior: HitTestBehavior.opaque)),
    ]);
  }

  Widget _buildRepairPanel(Color gold, bool isDragging) {
    final glowColor = _isUrgent ? Colors.redAccent : gold;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(isDragging ? 0.9 : 0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10)),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSuccess) ...[
                const Spacer(),
                Center(
                    child: Column(children: [
                  Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gold.withOpacity(0.1),
                          border: Border.all(color: gold.withOpacity(0.3))),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 80, color: gold)),
                  const SizedBox(height: 32),
                  Text('SUCCESS!',
                      style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text('Your request has been filed.',
                      style: GoogleFonts.kanit(
                          fontSize: 16, color: Colors.white38)),
                ])),
                const Spacer(),
              ] else if (_showConfirmation) ...[
                Expanded(child: _buildConfirmation(glowColor)),
              ] else ...[
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OBJECT',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: gold.withOpacity(0.7),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2)),
                            const SizedBox(height: 12),
                            Text(
                                _titleCtrl.text.isEmpty
                                    ? _selectedObjectName
                                    : _titleCtrl.text,
                                style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1)),
                          ]),
                      IconButton(
                          onPressed: _closePopup,
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white38)),
                    ]),
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Current Object', glowColor),
                          Text(_selectedObjectName,
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1)),
                          _buildLabel('Category', glowColor),
                          _PremiumDropdown(
                              selected: _selectedCategory,
                              items: _categories,
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v)),
                          const SizedBox(height: 24),
                          _buildLabel('Subject', glowColor),
                          _PremiumInput(
                              controller: _titleCtrl,
                              hint: 'e.g. Water leak...',
                              activeColor: glowColor),
                          const SizedBox(height: 24),
                          _buildLabel('Issue Details', glowColor),
                          _PremiumInput(
                              controller: _detailCtrl,
                              hint: 'Describe the issue...',
                              activeColor: glowColor,
                              maxLines: 3),
                          const SizedBox(height: 24),
                          _buildLabel('Appointment', glowColor),
                          Row(children: [
                            Expanded(
                                child: _ScheduleTrigger(
                                    label: 'Date',
                                    value: _selectedDate == null
                                        ? null
                                        : DateFormat('MMM dd')
                                            .format(_selectedDate!),
                                    icon: Icons.event,
                                    onTap: _pickDate,
                                    activeColor: glowColor)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _ScheduleTrigger(
                                    label: 'Time',
                                    value: _selectedTime?.format(context),
                                    icon: Icons.schedule,
                                    onTap: _pickTime,
                                    activeColor: glowColor)),
                          ]),
                          const SizedBox(height: 24),
                          _buildLabel('Photos', glowColor),
                          _PhotoPicker(
                              imagePaths: _attachedImages,
                              onTap: _pickImages,
                              onRemove: _removeImage,
                              activeColor: glowColor),
                          const SizedBox(height: 32),
                          _EmergencyToggle(
                              value: _isUrgent,
                              onChanged: (v) => setState(() => _isUrgent = v)),
                          const SizedBox(height: 32),
                          _buildWarrantyBadge(gold),
                          const SizedBox(height: 16),
                          _SubmitAction(
                              onTap: () {
                                if (_selectedCategory.isEmpty ||
                                    _titleCtrl.text.isEmpty ||
                                    _detailCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'กรุณาระบุหมวดหมู่ หัวข้อ และรายละเอียดปัญหาให้ครบถ้วน'),
                                          backgroundColor: Colors.redAccent));
                                  return;
                                }
                                setState(() => _showConfirmation = true);
                              },
                              isUrgent: _isUrgent,
                              gold: gold),
                          const SizedBox(height: 20),
                          Center(
                              child: Text('SECURE ENCRYPTED FILING',
                                  style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.white12,
                                      letterSpacing: 2))),
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

  Widget _buildLabel(String t, Color c) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t.toUpperCase(),
          style: GoogleFonts.shareTechMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: c.withOpacity(0.4),
              letterSpacing: 2)));

  Widget _buildWarrantyBadge(Color gold) {
    final expiryDate = DateTime.now().add(const Duration(days: 365 * 5));
    final expiryStr = DateFormat('dd/MM/yyyy').format(expiryDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: gold, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WARRANTY COVERAGE',
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10,
                    color: gold.withOpacity(0.6),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '5-Year Shield Active',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EXPIRES',
                style: GoogleFonts.shareTechMono(
                  fontSize: 9,
                  color: Colors.white24,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                expiryStr,
                style: GoogleFonts.shareTechMono(
                  fontSize: 13,
                  color: gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(Color glowColor) {
    final dateStr = _selectedDate == null
        ? 'N/A'
        : DateFormat('MMM dd, yyyy').format(_selectedDate!);
    final timeStr = _selectedTime?.format(context) ?? 'N/A';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FINAL REVIEW',
          style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5)),
      const SizedBox(height: 32),
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(label: 'Topic', value: _selectedCategory),
              _ReviewRow(label: 'Subject', value: _titleCtrl.text),
              _ReviewRow(label: 'Schedule', value: "$dateStr at $timeStr"),
              _ReviewRow(
                  label: 'Urgency',
                  value: _isUrgent ? 'EMERGENCY' : 'Regular',
                  isRed: _isUrgent),
              const Divider(color: Colors.white10, height: 48),
              _ReviewRow(
                label: 'Warranty',
                value: '5-Year Shield Active',
                isGreen: true,
              ),
              _ReviewRow(label: 'Est. Cost', value: '฿0.00', isBold: true),
              if (_attachedImages.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Evidence Gallery (${_attachedImages.length})',
                    style: GoogleFonts.shareTechMono(
                        color: Colors.white24, fontSize: 13, letterSpacing: 2)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _attachedImages.length,
                    itemBuilder: (context, idx) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_attachedImages[idx]),
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),
      _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                    child: _OverlayBtn(
                        label: 'Back',
                        color: Colors.white,
                        isOutline: true,
                        onTap: () =>
                            setState(() => _showConfirmation = false))),
                const SizedBox(width: 16),
                Expanded(
                    child: _OverlayBtn(
                        label: 'Confirm Submit',
                        color: glowColor,
                        onTap: _executeSubmission)),
              ],
            ),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildNewsTicker(Color gold) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.95),
        border: Border(top: BorderSide(color: gold.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [gold.withOpacity(0.2), gold.withOpacity(0.05)]),
              border: Border(right: BorderSide(color: gold.withOpacity(0.15))),
            ),
            child: Row(
              mainAxisSize: MainAxisSize
                  .min, // Fix: Prevent overflow by taking only needed space
              children: [
                Icon(Icons.campaign_rounded, color: gold, size: 16),
                const SizedBox(width: 8),
                Text(
                  TranslationService.instance.t('news_label'),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: gold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: ClipRect(
                  child: AnimatedBuilder(
                      animation: _tickerAnim,
                      builder: (context, child) {
                        final textStyle = GoogleFonts.outfit(fontSize: 13);
                        return LayoutBuilder(builder: (context, constraints) {
                          double itemWidth = 0;
                          for (var a in _announcements)
                            itemWidth += _measureText(a.text, textStyle) + 120;
                          return Transform.translate(
                              offset: Offset(
                                  constraints.maxWidth -
                                      (_tickerAnim.value * itemWidth),
                                  0),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ..._announcements,
                                    ..._announcements
                                  ]
                                      .expand((a) => [
                                            Icon(a.icon,
                                                color: a.color, size: 14),
                                            const SizedBox(width: 8),
                                            Text(a.text,
                                                style: GoogleFonts.kanit(
                                                    fontSize: 13,
                                                    color: Colors.white70)),
                                            const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 24),
                                                child: Text('●',
                                                    style: TextStyle(
                                                        color: Colors.white12,
                                                        fontSize: 8)))
                                          ])
                                      .toList()));
                        });
                      }))),
          Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: () => setState(() => _showTicker = false),
                  child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38, size: 18)))),
        ],
      ),
    );
  }

  double _measureText(String text, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr)
      ..layout();
    return tp.width;
  }
}

class _Announcement {
  final IconData icon;
  final Color color;
  final String text;
  const _Announcement(
      {required this.icon, required this.color, required this.text});
}

class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color activeColor;
  final int maxLines;
  const _PremiumInput(
      {required this.controller,
      required this.hint,
      required this.activeColor,
      this.maxLines = 1});

  @override
  State<_PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<_PremiumInput> {
  bool _isHovered = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
          animation: _focusNode,
          builder: (context, child) {
            final isFocused = _focusNode.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isFocused
                    ? widget.activeColor.withOpacity(0.05)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused
                      ? widget.activeColor
                      : (_isHovered ? Colors.white38 : Colors.white10),
                  width: isFocused ? 1.5 : 1.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                            color: widget.activeColor.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17),
                cursorColor: widget.activeColor,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.2), fontSize: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            );
          }),
    );
  }
}

class _PremiumDropdown extends StatefulWidget {
  final String selected;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onChanged;
  const _PremiumDropdown(
      {required this.selected, required this.items, required this.onChanged});

  @override
  State<_PremiumDropdown> createState() => _PremiumDropdownState();
}

class _PremiumDropdownState extends State<_PremiumDropdown> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _isHovered ? Colors.white38 : Colors.white10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.selected.isEmpty ? null : widget.selected,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A24),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: _isHovered ? Colors.white70 : Colors.white24),
            hint: Text('Select Category',
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16)),
            items: widget.items.expand((c) {
              final g = c['group'] as String;
              return (c['items'] as List<String>).map((i) => DropdownMenuItem(
                    value: '$g: $i',
                    child: Text('$g: $i',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal)),
                  ));
            }).toList(),
            onChanged: (v) => widget.onChanged(v ?? ''),
          ),
        ),
      ),
    );
  }
}

class _ScheduleTrigger extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final Color activeColor;
  const _ScheduleTrigger(
      {required this.label,
      this.value,
      required this.icon,
      required this.onTap,
      required this.activeColor});
  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: hasVal
                    ? activeColor.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: hasVal
                        ? activeColor.withOpacity(0.5)
                        : Colors.white10)),
            child: Column(children: [
              Icon(icon,
                  color: hasVal ? activeColor : Colors.white24, size: 24),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.shareTechMono(
                      fontSize: 10, color: Colors.white38)),
              Text(value ?? 'Set',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: hasVal ? FontWeight.bold : FontWeight.normal))
            ])));
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> imagePaths;
  final VoidCallback onTap;
  final Function(int) onRemove;
  final Color activeColor;
  const _PhotoPicker(
      {required this.imagePaths,
      required this.onTap,
      required this.onRemove,
      required this.activeColor});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10)),
              child: Row(children: [
                Icon(Icons.add_a_photo_rounded, color: activeColor, size: 24),
                const SizedBox(width: 16),
                Text('ATTACH PHOTOS',
                    style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1))
              ]))),
      if (imagePaths.isNotEmpty)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
                height: 80,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) => Stack(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(imagePaths[idx]),
                                  width: 80, height: 80, fit: BoxFit.cover)),
                          Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                  onTap: () => onRemove(idx),
                                  child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          size: 10, color: Colors.white))))
                        ]))))
    ]);
  }
}

class _EmergencyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _EmergencyToggle({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: value
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: value ? Colors.redAccent : Colors.white10)),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: value ? Colors.redAccent : Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                  child: Text('EMERGENCY DISPATCH',
                      style: GoogleFonts.shareTechMono(
                          color: value ? Colors.redAccent : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1))),
              _SimpleSwitch(value: value)
            ])));
  }
}

class _SimpleSwitch extends StatelessWidget {
  final bool value;
  const _SimpleSwitch({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 40,
        height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: value ? Colors.redAccent : Colors.white12,
            borderRadius: BorderRadius.circular(11)),
        child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white))));
  }
}

class _SubmitAction extends StatelessWidget {
  final VoidCallback onTap;
  final bool isUrgent;
  final Color gold;
  const _SubmitAction(
      {required this.onTap, required this.isUrgent, required this.gold});
  @override
  Widget build(BuildContext context) {
    final c = isUrgent ? Colors.redAccent : gold;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 76,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: c.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15))
                ]),
            alignment: Alignment.center,
            child: Text(isUrgent ? 'EXECUTE EMERGENCY' : 'SUBMIT DATA',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black))));
  }
}

class _TactileSlab extends StatelessWidget {
  final Widget child;
  const _TactileSlab({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10)),
        child: child);
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isRed;
  final bool isGreen;
  final bool isBold;
  const _ReviewRow(
      {required this.label,
      required this.value,
      this.isRed = false,
      this.isGreen = false,
      this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.shareTechMono(
                  color: Colors.white38, fontSize: 13, letterSpacing: 1)),
          Text(value,
              style: GoogleFonts.outfit(
                  color: isRed
                      ? Colors.redAccent
                      : (isGreen ? Colors.greenAccent : Colors.white),
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal))
        ]));
  }
}

class _OverlayBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutline;
  const _OverlayBtn(
      {required this.label,
      required this.color,
      required this.onTap,
      this.isOutline = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 60,
            decoration: BoxDecoration(
                color: isOutline ? Colors.transparent : color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3))),
            alignment: Alignment.center,
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isOutline ? Colors.white38 : Colors.black))));
  }
}
