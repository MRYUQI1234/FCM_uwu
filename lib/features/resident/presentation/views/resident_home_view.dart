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
import 'package:fcm_app/features/chat/data/repositories/ai_chat_repository.dart';
import 'package:fcm_app/core/services/translation_service.dart';
import 'package:fcm_app/shared/widgets/pin_verification_overlay.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// ═══════════════════════════════════════════════════════════
// Resident Home — Premium Always-On Display (V16.0: Final Polish & Accurate Logic)
// ═══════════════════════════════════════════════════════════

class ResidentHomeView extends StatefulWidget {
  final String displayUser;
  final String houseId;
  final String? activateDate;
  final bool isDark;
  final VoidCallback? onMenuTap;
  final VoidCallback? onHistoryRequested;

  const ResidentHomeView({
    super.key,
    required this.displayUser,
    required this.houseId,
    this.activateDate,
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
  String? _aiMessageId;
  String? _aiConversationId;

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

  // Values are translation keys: 'cat_appliances', 'cat_infrastructure', etc.
  static const Map<String, String> _objectCategoryMap = {
    // Appliances — matched against raw mesh name (lowercase, underscore)
    'aircon': 'cat_appliances',
    'condenser': 'cat_appliances',
    'fridge': 'cat_appliances',
    'stove': 'cat_appliances',
    'oven': 'cat_appliances',
    'washingmachine': 'cat_appliances',
    'dryer': 'cat_appliances',
    'water_heater': 'cat_appliances',
    'tv': 'cat_appliances',
    'tablet': 'cat_appliances',
    // Infrastructure
    'door': 'cat_infrastructure',
    'window': 'cat_infrastructure',
    'smartdoor': 'cat_infrastructure',
    'lock': 'cat_infrastructure',
    'light': 'cat_infrastructure',
    'switch': 'cat_infrastructure',
    'sink': 'cat_infrastructure',
    'tub': 'cat_infrastructure',
    'toilet': 'cat_infrastructure',
    'raintrack': 'cat_infrastructure',
    // Structure
    'wall': 'cat_structure',
    'floor': 'cat_structure',
    'ceiling': 'cat_structure',
    'roof': 'cat_structure',
    'rampart': 'cat_structure',
    'decoration': 'cat_structure',
    // Furniture
    'sofa': 'cat_furniture',
    'couch': 'cat_furniture',
    'tapis': 'cat_furniture',
    'closet': 'cat_furniture',
    'cabinet': 'cat_furniture',
    'drawer': 'cat_furniture',
    'bed': 'cat_furniture',
    'table': 'cat_furniture',
  };

  //ticler
  final List<_Announcement> _announcements = const [
    _Announcement(
        icon: Icons.water_drop_rounded,
        color: Color(0xFF60A5FA),
        text: 'Water Tank Cleaning — Water off 09:00 – 12:00 (Feb 15)'),
    // _Announcement(
    //     icon: Icons.bug_report_rounded,
    //     color: Color(0xFFFBBF24),
    //     text: 'Mosquito Spraying — Close all windows & doors (Feb 20)'),
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
              //ไม่จำเป็น
              // if (window._fcmRoofVis === undefined) 
              // window._fcmRoofVis = true;

              window._fcmRoofVis = !window._fcmRoofVis;
              const state = window._fcmRoofVis;

              //สปาเก็ตตี้
              // const isProtected = n => {
              //     let c = n; while(c) { const nm=(c.name||'').toLowerCase();
              //         if(nm.includes('couch')||nm.includes('sofa')||nm.includes('door')||nm.includes('gate')||nm.includes('window'))return true;
              //         c=c.parent; } return false;
              // };

              document.querySelectorAll('model-viewer').forEach(mv => {
                  const scene = getScene(mv); 
                  
                  if(!scene)return;

                  scene.traverse(node => {
                      // if(isProtected(node))return;

                      //ชื่อ obj
                      const l=(node.name||'').toLowerCase().trim();
                      if(l.includes('cube032')||l.includes('roof')) 
                        node.visible=state;
                  });
              });
          };

          window.toggleWall = function()
          {
            window._fcmWallVis = !window._fcmWallVis;
            const state = window._fcmWallVis;

            document.querySelectorAll('model-viewer').forEach(mv => {
                const scene = getScene(mv); 
                
                if(!scene)return;

                scene.traverse(node => {
                    // if(isProtected(node))return;

                    //ชื่อ obj
                    const l=(node.name||'').toLowerCase().trim();

                    //เงื่อนไข
                    if(l.includes('cube032')||l.includes('roof')) 
                      node.visible=state;
                });
            });
          }

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
                          const selectionIgnore = [];//['wall', 'floor', 'ceiling', 'bed', 'vase', 'plant', 'tapis', 'carpet', 'rug', 'curtain', 'blind', 'glass', 'stone', 'louvers', 'pillar', 'beam', 'brick', 'stair', 'grass', 'ground', 'sky', 'fence', 'decoration', 'rampart', 'sofa', 'couch', 'coffee_table', 'tv_closet', 'drawer'];
                          const interactive = ['aircon', 'toilet', 'sink', 'tub', 'stove', 'fridge', 'refrigerator', 'door', 'window', 'light', 'switch', 'washing', 'dryer', 'smart', 'condenser', 'lock', 'tablet', 'tv', 'closet', 'cabinet', 'raintrack', 'roof'];
                          const propIds = ['unselectable'];
                          
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

      // Strip hierarchy suffix, e.g. 'bathroom_door [bathroom_door>...]' → 'bathroom_door'
      String shortName = name.split(' [').first.toLowerCase();
      // Strip numeric suffix (e.g. '.001') for key lookup
      final cleanKey = shortName.replaceAll(RegExp(r'\.\d+$'), '');
      // Build the obj_* translation key
      final objKey = _getMeshTranslationKey(cleanKey);

      // Derive category key from raw mesh name
      String catKey = '';
      _objectCategoryMap.forEach((keyword, catTransKey) {
        if (cleanKey.contains(keyword)) catKey = catTransKey;
      });

      final ts = TranslationService.instance;
      final translatedName = ts.t(objKey);

      setState(() {
        _selectedObjectName = objKey; // store translation key
        _selectedCategory = catKey; // store 'cat_*' key
        _cameraTarget = focusPos;
        _repairFabOffset.value = const Offset(40, 110);
        _titleCtrl.text =
            translatedName; // pre-fill subject with translated name
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

  /// Returns the obj_* translation key for a raw GLB mesh name.
  /// Falls back to a generated key if no exact match is found.
  String _getMeshTranslationKey(String meshName) {
    // Map of raw glb mesh keys → obj_* translation keys
    const Map<String, String> keyMap = {
      // Bathroom
      'bathroom_door': 'obj_bathroom_door',
      'bathroom_light': 'obj_bathroom_light',
      'bathroom_light_switch': 'obj_bathroom_light_switch',
      'bathroom_sink': 'obj_bathroom_sink',
      'bathroom_tub': 'obj_bathroom_tub',
      'bathroom_toilet': 'obj_bathroom_toilet',
      'bathroom_window': 'obj_bathroom_window',
      'bathroom_floor': 'obj_bathroom_floor',
      'bathroom_wall': 'obj_bathroom_wall',
      // Exterior
      'exterior_back_raintrack': 'obj_exterior_back_raintrack',
      'exterior_left_condenser': 'obj_exterior_left_condenser',
      'exterior_right_condenser': 'obj_exterior_right_condenser',
      'exterior_roof': 'obj_exterior_roof',
      'exterior_front_roof': 'obj_exterior_front_roof',
      'exterior_back_wall': 'obj_exterior_back_wall',
      'exterior_front_entrance_decoration':
          'obj_exterior_front_entrance_decoration',
      'exterior_front_rampart': 'obj_exterior_front_rampart',
      'exterior_front_stone_decoration': 'obj_exterior_front_stone_decoration',
      'exterior_front_wall': 'obj_exterior_front_wall',
      'exterior_front_wood_decoration': 'obj_exterior_front_wood_decoration',
      'exterior_left_wall': 'obj_exterior_left_wall',
      'exterior_left_wood_decoration': 'obj_exterior_left_wood_decoration',
      'exterior_right_wall': 'obj_exterior_right_wall',
      // Kitchen
      'kitchen_light': 'obj_kitchen_light',
      'kitchen_light_switch': 'obj_kitchen_light_switch',
      'kitchen_sink': 'obj_kitchen_sink',
      'kitchen_fridge': 'obj_kitchen_fridge',
      'kitchen_stove': 'obj_kitchen_stove',
      'kitchen_hanged_cabinet': 'obj_kitchen_hanged_cabinet',
      'kitchen_small_floor_cabinet': 'obj_kitchen_small_floor_cabinet',
      'kitchen_window': 'obj_kitchen_window',
      'kitchen_floor': 'obj_kitchen_floor',
      'kitchen_wall': 'obj_kitchen_wall',
      // Living Room
      'livingroom_light': 'obj_livingroom_light',
      'livingroom_light_switch': 'obj_livingroom_light_switch',
      'livingroom_lock': 'obj_livingroom_lock',
      'livingroom_smartdoor': 'obj_livingroom_smartdoor',
      'livingroom_smartdoor_tablet': 'obj_livingroom_smartdoor_tablet',
      'livingroom_tv': 'obj_livingroom_tv',
      'livingroom_tv_closet': 'obj_livingroom_tv_closet',
      'livingroom_window': 'obj_livingroom_window',
      'livingroom_carpet': 'obj_livingroom_carpet',
      'livingroom_coffe_table': 'obj_livingroom_coffe_table',
      'livingroom_floor': 'obj_livingroom_floor',
      'livingroom_sofa': 'obj_livingroom_sofa',
      'livingroom_tapis': 'obj_livingroom_tapis',
      'livingroom_wall': 'obj_livingroom_wall',
      // Main Bedroom
      'main_bedroom_aircon': 'obj_main_bedroom_aircon',
      'main_bedroom_aircon_remote': 'obj_main_bedroom_aircon_remote',
      'main_bedroom_bathroom_door': 'obj_main_bedroom_bathroom_door',
      'main_bedroom_bathroom_light': 'obj_main_bedroom_bathroom_light',
      'main_bedroom_bathroom_light_switch':
          'obj_main_bedroom_bathroom_light_switch',
      'main_bedroom_bathroom_sink': 'obj_main_bedroom_bathroom_sink',
      'main_bedroom_bathroom_toilet': 'obj_main_bedroom_bathroom_toilet',
      'main_bedroom_bathroom_tub': 'obj_main_bedroom_bathroom_tub',
      'main_bedroom_bathroom_window': 'obj_main_bedroom_bathroom_window',
      'main_bedroom_door': 'obj_main_bedroom_door',
      'main_bedroom_drawer': 'obj_main_bedroom_drawer',
      'main_bedroom_light': 'obj_main_bedroom_light',
      'main_bedroom_light_switch': 'obj_main_bedroom_light_switch',
      'main_bedroom_window': 'obj_main_bedroom_window',
      'main_bedroom_bed': 'obj_main_bedroom_bed',
      'main_bedroom_tapis': 'obj_main_bedroom_tapis',
      'main_bedroom_floor': 'obj_main_bedroom_floor',
      'main_bedroom_wall': 'obj_main_bedroom_wall',
      'main_bedroom_bathroom_floor': 'obj_main_bedroom_bathroom_floor',
      'main_bedroom_bathroom_wall': 'obj_main_bedroom_bathroom_wall',

      // Secondary Bedroom
      'secondary_bedroom_aircon': 'obj_secondary_bedroom_aircon',
      'secondary_bedroom_aircon_remote': 'obj_secondary_bedroom_aircon_remote',
      'secondary_bedroom_closet': 'obj_secondary_bedroom_closet',
      'secondary_bedroom_door': 'obj_secondary_bedroom_door',
      'secondary_bedroom_light': 'obj_secondary_bedroom_light',
      'secondary_bedroom_light_switch': 'obj_secondary_bedroom_light_switch',
      'secondary_bedroom_window': 'obj_secondary_bedroom_window',
      'secondary_bedroom_floor': 'obj_secondary_bedroom_floor',
      'secondary_bedroom_red': 'obj_secondary_bedroom_red',
      'secondary_bedroom_wall': 'obj_secondary_bedroom_wall',
      // Washroom
      'washingmachine': 'obj_washingmachine',
      'washroom_door': 'obj_washroom_door',
      'washroom_dryer': 'obj_washroom_dryer',
      'washroom_light': 'obj_washroom_light',
      'washroom_switch': 'obj_washroom_switch',
      'washroom_window': 'obj_washroom_window',
      'washroom_floor': 'obj_washroom_floor',
      'washroom_wall': 'obj_washroom_wall',
    };

    // Exact match
    if (keyMap.containsKey(meshName)) return keyMap[meshName]!;

    // Longest-match strategy (to prefer more specific keys like 'main_bedroom_bathroom_wall' over 'main_bedroom_wall')
    String? bestKey;
    int maxLen = -1;

    for (final entry in keyMap.entries) {
      if (meshName.contains(entry.key)) {
        if (entry.key.length > maxLen) {
          maxLen = entry.key.length;
          bestKey = entry.value;
        }
      }
    }

    if (bestKey != null) return bestKey;

    // Fallback: return the raw mesh name itself so t() can display it cleanly
    return meshName;
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
      _aiMessageId = null;
      _aiConversationId = null;
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

    // PIN verification before submitting
    final pinOk = await showPinVerificationOverlay(context);
    if (pinOk != true) return;

    setState(() => _isSubmitting = true);

    final success = await RepairRepository.instance.submitRequest(
      title: _titleCtrl.text.isEmpty
          ? TranslationService.instance.t(_selectedObjectName)
          : _titleCtrl.text,
      description: _detailCtrl.text,
      isEmergency: _isUrgent,
      appointmentDate: _selectedDate,
      appointmentTime: _selectedTime,
      objectId: _selectedObjectName,
      objectType: _selectedCategory,
      imagePaths: _attachedImages,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _showConfirmation = false;
          _showSuccess = true;
          
          // Complete the AI Chat flow if applicable
          if (_aiMessageId != null && _aiConversationId != null) {
            AIChatRepository.instance.updateMessageActionState(_aiMessageId!, 'confirmed');
            AIChatRepository.instance.archiveConversation(_aiConversationId!);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to submit repair request. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }

    //ไปหน้าประวัติ
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

    //โมเดล 3 มิติ
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              key: const ValueKey('fcm_v16_full'),
              id: 'fcmHouseModel',
              src: 'assets/models/Vivorn7.8.glb',
              alt: 'FCM House Model',
              autoRotate: false,
              cameraControls: true,
              backgroundColor:
                  widget.isDark ? Colors.transparent : Colors.white,
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
          // ส่วนของคำทักทาย
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
                //ส่วนปุ่มเปิดหลังคา
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => js.context.callMethod('toggleRoof'),
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color:
                              widget.isDark ? Colors.black26 : Colors.white24,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white24, width: 1.5)),
                      child: Icon(Icons.roofing_rounded, color: gold, size: 26),
                    ),
                  ),
                ),
                //วันที่เวลา
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
                          fontWeight: FontWeight.bold,
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
                    },
                    onTaskTap: (requestData, tasks, msgId, convoId) {
                      if (tasks.isEmpty) return;
                      final firstTask = tasks.first;
                      setState(() {
                        _showAIChatPanel = false;
                        _showRepairPopup = true;
                        _aiMessageId = msgId;
                        _aiConversationId = convoId;
                        _selectedObjectName = firstTask.objectId ?? '';
                        _selectedCategory = firstTask.objectType;
                        _isUrgent = firstTask.urgency == 'emergency' ||
                            (requestData['type'] == 'URGENT');
                        _titleCtrl.text =
                            requestData['title'] ?? firstTask.objectName ?? '';
                        _detailCtrl.text = firstTask.description;

                        // Pre-select date if AI suggested one
                        if (firstTask.preferDate != null) {
                          try {
                            final dt = DateTime.parse(firstTask.preferDate!);
                            _selectedDate = dt;
                            
                            if (firstTask.preferTime != null) {
                              final parts = firstTask.preferTime!.split(':');
                              if (parts.length >= 2) {
                                _selectedTime = TimeOfDay(
                                  hour: int.tryParse(parts[0]) ?? 9,
                                  minute: int.tryParse(parts[1]) ?? 30,
                                );
                              }
                            } else {
                              // If no time is explicitly set, left it empty or default
                              _selectedTime = null;
                            }
                          } catch (e) {
                            debugPrint('Error parsing AI date/time: $e');
                          }
                        }
                      });
                      _popupAnim.forward(from: 0);
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
              color: widget.isDark ? Colors.black87 : Colors.white70,
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
                            Text(
                                TranslationService.instance
                                    .t('repair_label_object')
                                    .toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: gold.withOpacity(0.7),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2)),
                            const SizedBox(height: 8),
                            Text(
                                TranslationService.instance
                                    .t(_selectedObjectName),
                                style: GoogleFonts.outfit(
                                    fontSize: 30,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1)),
                          ]),
                      IconButton(
                          onPressed: _closePopup,
                          icon: Icon(Icons.close_rounded,
                              color: widget.isDark
                                  ? Colors.white38
                                  : Colors.black38)),
                    ]),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Category chip (read-only) ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_category'),
                              glowColor),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: glowColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: glowColor.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.category_rounded,
                                    size: 16, color: glowColor),
                                const SizedBox(width: 8),
                                Text(
                                    _selectedCategory.isEmpty
                                        ? TranslationService.instance
                                            .t('repair_label_uncategorized')
                                        : TranslationService.instance
                                            .t(_selectedCategory),
                                    style: GoogleFonts.outfit(
                                        color: widget.isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // ── Subject ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_subject'),
                              glowColor),
                          _PremiumInput(
                              controller: _titleCtrl,
                              hint: TranslationService.instance
                                  .t('repair_hint_subject'),
                              activeColor: glowColor,
                              isDark: widget.isDark),
                          const SizedBox(height: 24),
                          // ── Issue Details ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_detail'),
                              glowColor),
                          _PremiumInput(
                              controller: _detailCtrl,
                              hint: TranslationService.instance
                                  .t('repair_hint_detail'),
                              activeColor: glowColor,
                              isDark: widget.isDark,
                              maxLines: 3),
                          const SizedBox(height: 24),
                          // ── Date ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_date'),
                              glowColor),
                          _ScheduleTrigger(
                              label: TranslationService.instance
                                  .t('repair_slot_date'),
                              value: _selectedDate == null
                                  ? null
                                  : DateFormat('MMM dd').format(_selectedDate!),
                              icon: Icons.event,
                              onTap: _pickDate,
                              activeColor: glowColor,
                              isDark: widget.isDark),
                          const SizedBox(height: 16),
                          // ── Time Slots ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_slot'),
                              glowColor),
                          Row(children: [
                            Expanded(
                              child: _TimeSlotButton(
                                label: '9:30 – 12:00',
                                selected: _selectedTime ==
                                    const TimeOfDay(hour: 9, minute: 30),
                                activeColor: glowColor,
                                isDark: widget.isDark,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 9, minute: 30)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeSlotButton(
                                label: '13:00 – 16:00',
                                selected: _selectedTime ==
                                    const TimeOfDay(hour: 13, minute: 0),
                                activeColor: glowColor,
                                isDark: widget.isDark,
                                onTap: () => setState(() => _selectedTime =
                                    const TimeOfDay(hour: 13, minute: 0)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          // ── Photos ──
                          _buildLabel(
                              TranslationService.instance
                                  .t('repair_label_photos'),
                              glowColor),
                          _PhotoPicker(
                            imagePaths: _attachedImages,
                            onTap: _pickImages,
                            onRemove: _removeImage,
                            activeColor: glowColor,
                            isDark: widget.isDark,
                          ),
                          const SizedBox(height: 32),
                          _EmergencyToggle(
                              value: _isUrgent,
                              onChanged: (v) => setState(() => _isUrgent = v)),
                          const SizedBox(height: 32),
                          _buildWarrantyBadge(gold),
                          const SizedBox(height: 16),
                          _SubmitAction(
                              onTap: () {
                                if (_titleCtrl.text.isEmpty ||
                                    _detailCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(TranslationService
                                              .instance
                                              .t('repair_validation_error')),
                                          backgroundColor: Colors.redAccent));
                                  return;
                                }
                                if (_selectedDate == null ||
                                    _selectedTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(TranslationService
                                              .instance
                                              .t('repair_validation_datetime')),
                                          backgroundColor: Colors.redAccent));
                                  return;
                                }
                                setState(() => _showConfirmation = true);
                              },
                              isUrgent: _isUrgent,
                              gold: gold),
                          const SizedBox(height: 20),
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
    DateTime expiryDate;
    if (widget.activateDate != null && widget.activateDate!.isNotEmpty) {
      try {
        final activated = DateTime.parse(widget.activateDate!);
        expiryDate =
            DateTime(activated.year + 5, activated.month, activated.day);
      } catch (e) {
        expiryDate = DateTime.now().add(const Duration(days: 365 * 5));
      }
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 365 * 5));
    }
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
  final bool isDark;
  const _PremiumInput(
      {required this.controller,
      required this.hint,
      required this.activeColor,
      this.maxLines = 1,
      this.isDark = true});

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
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor =
        widget.isDark ? Colors.white.withOpacity(0.2) : Colors.black26;
    final bgColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    final borderIdle = widget.isDark ? Colors.white10 : Colors.black12;
    final borderHover = widget.isDark ? Colors.white38 : Colors.black38;
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
                color:
                    isFocused ? widget.activeColor.withOpacity(0.05) : bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused
                      ? widget.activeColor
                      : (_isHovered ? borderHover : borderIdle),
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
                style: GoogleFonts.outfit(color: textColor, fontSize: 17),
                cursorColor: widget.activeColor,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 16),
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
  final List<String> items;
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
            items: widget.items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal)),
                    ))
                .toList(),
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
  final bool isDark;
  const _ScheduleTrigger(
      {required this.label,
      this.value,
      required this.icon,
      required this.onTap,
      required this.activeColor,
      this.isDark = true});
  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    final textColor = isDark ? Colors.white : Colors.black87;
    final emptyBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    final emptyBorder = isDark ? Colors.white10 : Colors.black12;
    final labelColor = isDark ? Colors.white38 : Colors.black38;
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: hasVal ? activeColor.withOpacity(0.1) : emptyBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        hasVal ? activeColor.withOpacity(0.5) : emptyBorder)),
            child: Column(children: [
              Icon(icon,
                  color: hasVal
                      ? activeColor
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 24),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.shareTechMono(
                      fontSize: 10, color: labelColor)),
              Text(value ?? 'Set',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: hasVal ? FontWeight.bold : FontWeight.normal))
            ])));
  }
}

class _TimeSlotButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;
  const _TimeSlotButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
    this.isDark = true,
  });
  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final emptyBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);
    final emptyBorder = isDark ? Colors.white10 : Colors.black12;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.15) : emptyBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : emptyBorder,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: selected ? activeColor : textColor.withOpacity(0.6),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
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
  final bool isDark;
  const _PhotoPicker(
      {required this.imagePaths,
      required this.onTap,
      required this.onRemove,
      required this.activeColor,
      required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                  color: this.isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10)),
              child: Row(children: [
                Icon(Icons.add_a_photo_rounded, color: activeColor, size: 24),
                const SizedBox(width: 16),
                Text('ATTACH PHOTOS',
                    style: GoogleFonts.shareTechMono(
                        color: this.isDark ? Colors.white70 : Colors.black87,
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
