import 'dart:async';
import 'dart:ui';
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
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

// ═══════════════════════════════════════════════════════════
// Resident Home — Premium Always-On Display (V9.0: Group-Aware Ghosting)
// ═══════════════════════════════════════════════════════════

class ResidentHomeView extends StatefulWidget {
  final String displayUser;
  final String houseId;
  final bool isDark;

  const ResidentHomeView({
    super.key,
    required this.displayUser,
    required this.houseId,
    required this.isDark,
  });

  @override
  State<ResidentHomeView> createState() => _ResidentHomeViewState();
}

class _ResidentHomeViewState extends State<ResidentHomeView>
    with TickerProviderStateMixin {
  late Timer _clockTimer;
  String _timeStr = '';
  String _greeting = '';

  late AnimationController _tickerAnim;

  // ── Repair Popup State ──
  late AnimationController _popupAnim;
  bool _showRepairPopup = false;
  String _selectedObjectName = '';
  String _selectedObjectRaw = '';
  final _titleCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _isUrgent = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  // --- Full SRS Form State ---
  String _selectedCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedSlot;
  List<String> _attachedImages = [];
  bool _showConfirmation = false;
  final ValueNotifier<Offset> _popupOffset = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false); 
  final ValueNotifier<Offset> _fabOffset = ValueNotifier<Offset>(const Offset(40, 100));
  final ValueNotifier<bool> _isFabDragging = ValueNotifier<bool>(false);
  Widget? _cachedRepairPanel;
  double _lastFrameMs = 0;
  DateTime? _lastDragTime;

  // ── Camera State ──
  String _cameraTarget = 'auto 1.2m auto';
  String _cameraOrbit = '45deg 60deg 90%';
  final String _defaultTarget = 'auto 1.2m auto';
  final String _defaultOrbit = '45deg 60deg 90%';
  final ImagePicker _picker = ImagePicker();
  final DateTime _transferDate = DateTime(2022, 10, 10);

  final _categories = [
    {'group': 'HVAC & Appliances', 'items': ['Air Conditioner', 'Refrigerator', 'Oven', 'Washing Machine']},
    {'group': 'Infrastructure', 'items': ['Doors/Windows', 'Lighting', 'Plumbing']},
    {'group': 'Structure & Build', 'items': ['Wall', 'Floor', 'Ceiling', 'Roof']},
    {'group': 'Furniture & Decor', 'items': ['Sofa/Carpet', 'Closet/Cabinet', 'Bed/Table', 'Wall Tablet']},
  ];

  static const Map<String, String> _objectCategoryMap = {
    'bathtub': 'Infrastructure: Plumbing',
    'toilet': 'Infrastructure: Plumbing',
    'water heater': 'HVAC & Appliances: Washing Machine', // Closest match or add new if needed
    'basin': 'Infrastructure: Plumbing',
    'mirror': 'Furniture & Decor: Sofa/Carpet',
    'refrigerator': 'HVAC & Appliances: Refrigerator',
    'fridge': 'HVAC & Appliances: Refrigerator',
    'sink': 'Infrastructure: Plumbing',
    'stove': 'HVAC & Appliances: Oven',
    'oven': 'HVAC & Appliances: Oven',
    'air conditioner': 'HVAC & Appliances: Air Conditioner',
    'ac remote': 'HVAC & Appliances: Air Conditioner',
    'tv': 'HVAC & Appliances: Air Conditioner', // Placeholder
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

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());

    _tickerAnim = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 40),
    )..repeat();

    _popupAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ── JS INTEROP: V13.0 Flex-Match & Debug Bridge ──
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

  String _formatObjectName(String rawName) {
    final lower = rawName.toLowerCase();

    // 0. Handle exact keywords which are specific to certain objects
    // without catching every '.00x' variations in the detailed map
    if (lower == 'plane') return 'MainbedroomWall3';
    if (lower == 'floor' || lower == 'floors') return 'Laundry Floor';
    
    // 1. Detailed specific mapping based on extracted GLB node names
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
      'plane.008': 'SecBedroomWall1',
      'plane008': 'SecBedroomWall1',
      'plane.012': 'SecBedroomWall2',
      'plane012': 'SecBedroomWall2',
      'plane.007': 'SecBedroomWall3',
      'plane007': 'SecBedroomWall3',
      'plane.025': 'SecbedroomWall4',
      'plane025': 'SecbedroomWall4',
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
      'strike plate 01001': 'Smart Door Lock',
      'strike_plate_01001': 'Smart Door Lock',
      
      // Right Windows
      'handle.002': 'RightWindow1',
      'handle002': 'RightWindow1',
      'windowr.002': 'RightWindow3',
      'windowr002': 'RightWindow3',
      
      // Back Windows
      'windowframe.007': 'RearWindow1',
      'windowframe007': 'RearWindow1',
      'windowl.006': 'RearWindow2',
      'windowl006': 'RearWindow2',
      
      // Left Windows
      'handle.009': 'LeftWindow1',
      'handle009': 'LeftWindow1',
      'windowr.005': 'LeftWindow2',
      'windowr005': 'LeftWindow2',
      
      // Front Windows
      'windowr.003': 'FrontWindow',
      'windowr003': 'FrontWindow',

      // Generic Matches (Must be AFTER specific matches)
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
      
      // Appliances & Tech
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
      
      // Lighting (Specific Types)
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
      
      // Furniture
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
      
      // Bathroom
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

    // Check for specific matches first
    for (final entry in detailedMap.entries) {
      if (lower.contains(entry.key)) {
        String base = entry.value;
        // If it has a suffix like .001, preserve it as a readable number
        if (rawName.contains('.')) {
          final suffix = rawName.split('.').last;
          if (RegExp(r'^\d+$').hasMatch(suffix)) {
            return '$base ${int.parse(suffix)}';
          }
        }
        return base;
      }
    }

    // 2. Fallback: Systematic cleanup
    String cleaned = rawName.replaceAll(RegExp(r'[_.]'), ' ').trim();
    
    // Convert "Modern Ceiling Light 01.002" -> "Ceiling Light 2"
    cleaned = cleaned.replaceAll(RegExp(r'Modern Ceiling Light 01', caseSensitive: false), 'Ceiling Light');
    cleaned = cleaned.replaceAll(RegExp(r'Double spot light', caseSensitive: false), 'Spot Light');
    
    // General numeric split: "Plane014" -> "Plane 014"
    cleaned = cleaned.replaceAllMapped(RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]} ${m[2]}');
    
    // Replace "Plane" with "Wall"
    cleaned = cleaned.replaceAll(RegExp(r'plane', caseSensitive: false), 'Wall');
    
    // Standardize Lighting numbers
    if (lower.startsWith('light') || lower.startsWith('point') || lower.startsWith('spot')) {
      cleaned = cleaned.replaceAll(RegExp(r'light|point|spot', caseSensitive: false), 'Light Fixture');
    }

    // Title Case
    if (cleaned.isNotEmpty) {
      cleaned = cleaned.split(' ').map((word) {
        if (word.isEmpty) return '';
        final w = word.toLowerCase();
        // Keep small words lowercase unless it's the first word
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    
    return cleaned;
  }

  void _handleObjectClick(dynamic rawData) {
    if (rawData is String) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (rawData.isEmpty) return;

      String name = '';
      String focusPos = '';

      try {
        if (rawData.startsWith('{')) {
          final data = jsonDecode(rawData);
          name = data['name'] ?? '';
          focusPos = data['focus'] ?? '';
        } else {
          name = rawData;
        }
      } catch (e) {
        name = rawData;
      }

      if (name.isEmpty) return;

      String shortName = name.split(' [').first;
      String displayName = _formatObjectName(shortName);

      // Map to category
      String objLower = displayName.toLowerCase();
      String newCategory = '';
      _objectCategoryMap.forEach((key, value) {
        if (objLower.contains(key)) newCategory = value;
      });

      try {
        // Show immersive repair popup
        setState(() {
          _selectedObjectName = displayName;
          _selectedObjectRaw = shortName;
          _titleCtrl.text = displayName;
          _detailCtrl.clear();
          _isUrgent = false;
          _isSubmitting = false;
          _showSuccess = false;
          _showRepairPopup = true;
          _selectedCategory = newCategory;
          _selectedDate = null;
          _selectedTime = null;
          _attachedImages = [];
          _showConfirmation = false;
          _popupOffset.value = Offset.zero; // Reset position for new selection

          // ★ Focus camera on object — TARGET + Subtle Zoom (Force NO Rotation)
          if (focusPos.isNotEmpty) {
            _cameraTarget = focusPos;
            // Pass a multiplier (0.7 = zoom in 30%) to the JS helper
            js.context.callMethod('fcmFocus', [_cameraTarget, 0.7]);
          }
        });
        _popupAnim.forward(from: 0.0);
      } catch (e) {
        js.context.callMethod('fcmDebugLog', ["Dart Selection Error: ${e.toString()}"]);
      }
    }
  }

  void _closePopup() {
    _popupAnim.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showRepairPopup = false;
        });
      }
    });
  }

  bool _checkWarranty() {
    final expiryDate = DateTime(_transferDate.year + 5, _transferDate.month, _transferDate.day);
    return DateTime.now().isBefore(expiryDate);
  }

  double _calculateCost() {
    if (_checkWarranty()) return 0.0;
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

  bool _isValidTime(TimeOfDay time) {
    final double minutes = time.hour * 60.0 + time.minute;
    final bool isAM = minutes >= (9 * 60 + 30) && minutes <= (12 * 60);
    final bool isPM = minutes >= (13 * 60) && minutes <= (16 * 60);
    return isAM || isPM;
  }

  /// Categorize whether an object is repairable/selectable or just decorative/structural
  bool _isSelectable(String name) {
    final lower = name.toLowerCase();
    
    // 1. Prioritize repairable items (High interactive value)
    const allowed = [
      'air conditioner', 'ac ', 'toilet', 'sink', 'bathtub', 'stove', 'fridge', 
      'refrigerator', 'panel', 'door', 'window', 'light', 'fixture', 'switch',
      'washing', 'dryer', 'smart', 'pump', 'condenser', 'lock', 'handle', 'faucet',
      'shower', 'cabinet', 'closet', 'sensor', 'intercom', 'unit'
    ];
    
    for (var a in allowed) {
       if (lower.contains(a)) return true;
    }

    // 2. Explicitly ignore structural or purely decorative objects
    const ignored = [
      'wall', 'floor', 'roof', 'ceiling', 'bed', 'vase', 'plant', 
      'coffee table', 'carpet', 'rug', 'curtain', 'blind', 'glass',
      'mullion', 'frame', 'porch', 'extension', 'stone', 'louvers', 
      'pillar', 'beam', 'brick', 'stair', 'grass', 'ground', 'sky', 'fence'
    ];
    
    for (var i in ignored) {
      if (lower.contains(i)) return false;
    }
    
    return true; // Default to true if not specifically ignored
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 30),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) {
      if (_isValidTime(picked)) {
        setState(() {
          _selectedTime = picked;
          _selectedSlot = (picked.hour < 12) ? 'AM' : 'PM';
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกเวลาในช่วง 09:30-12:00 หรือ 13:00-16:00'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) setState(() => _attachedImages.addAll(images.map((img) => img.path)));
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) => setState(() => _attachedImages.removeAt(index));

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

  Future<void> _executeSubmission() async {
    if (_titleCtrl.text.trim().isEmpty || _detailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาระบุหัวข้อและรายละเอียดปัญหาให้ครบถ้วน', style: GoogleFonts.kanit()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.dark(),
        child: AlertDialog(
          backgroundColor: const Color(0xFF16161C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
          title: Text('ยืนยันการส่งข้อมูล?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text('คุณตรวจสอบข้อมูลทั้งหมดแล้ว และพร้อมที่จะส่งเพื่อดำเนินการซ่อมแซมใช่หรือไม่?', style: GoogleFonts.kanit(color: Colors.white70)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('ยกเลิก', style: GoogleFonts.kanit(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUrgent ? Colors.redAccent : DashboardTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('ยืนยัน', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() { _isSubmitting = true; });
    
    // Pass full payload to mocked backend
    RepairRepository.instance.addRequest(
      title: _titleCtrl.text.isEmpty ? _selectedObjectName : _titleCtrl.text,
      description: _detailCtrl.text.trim(),
      isEmergency: _isUrgent,
      // Pass other required fields with logic data
      appointmentSlot: _selectedSlot ?? 'AM',
    );

    await Future.delayed(const Duration(milliseconds: 800)); // Mock network delay
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _showConfirmation = false;
      _showSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _closePopup();
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
    _fabOffset.dispose();
    _isFabDragging.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    setState(() {
      _timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    });
  }

  @override
  Widget build(BuildContext context) {
    final gold = DashboardTheme.primary;
    final bgColor = const Color(0xFF0F0F15);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ModelViewer(
                    key: const ValueKey('fcm_main_model_stable'),
                    src: 'assets/models/VivornFinal8.4.glb',
                    alt: 'FCM House Model',
                    autoRotate: true,
                    autoPlay: true,
                    cameraControls: true,
                    disablePan: false,
                    backgroundColor: bgColor,
                    exposure: 1.0,
                    shadowIntensity: 1.0,
                    loading: Loading.eager,
                    rotationPerSecond: '6deg',
                    cameraTarget: _cameraTarget,
                    cameraOrbit: _cameraOrbit,
                    minCameraOrbit: 'auto 5deg 0%',
                    maxCameraOrbit: 'auto 85deg auto',
                    interpolationDecay: 200,
                    id: 'fcmHouseModel',
                    relatedJs: "document.getElementById('fcmHouseModel').setAttribute('zoom-sensitivity', '0.3');",
                  ),

                ],
              ),
            ),
          ),

          // Header
          Positioned(
            top: 32, left: 40, right: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_greeting,', style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60, letterSpacing: 2)),
                      Text(widget.displayUser, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              try { js.context.callMethod('toggleRoof'); } catch (e) { print(e); }
                            },
                            borderRadius: BorderRadius.circular(40),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                                ],
                              ),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(Icons.roofing_rounded, color: gold, size: 26),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Text(_timeStr, style: GoogleFonts.outfit(fontSize: 42, color: Colors.white, fontWeight: FontWeight.w200, letterSpacing: 4)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // TICKER
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.black.withOpacity(0.5), Colors.transparent],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 40, top: 0, bottom: 0,
                    child: Center(
                      child: Row(
                        children: [
                          Text("NEWS REPORT:", style: GoogleFonts.anton(color: gold, fontSize: 16, letterSpacing: 1)),
                          const SizedBox(width: 16),
                          Container(width: 1, height: 20, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    left: 200,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _tickerAnim,
                        builder: (context, child) {
                          double screenWidth = MediaQuery.of(context).size.width;
                          double progress = _tickerAnim.value;
                          return Transform.translate(
                            offset: Offset((1 - progress) * (screenWidth + 1600) - 800, 0),
                            child: child,
                          );
                        },
                        child: Center(
                          child: Text(
                            "ล้างแท็งก์น้ำส่วนกลาง (15 ก.พ. 2569) - จะมีการปิดน้ำช้าวคราวเวลา 09:00 - 12:00 น.     |     ฉีดพ่นยากำจัดยุง (20 ก.พ. 2569) - กรุณาปิดหน้าต่างและประตูบ้านให้มิดชิด     |     ประชุมใหญ่สามัญประจำปี (25 ก.พ. 2569) - ณ สโมสรส่วนกลาง เวลา 18:00 น. เป็นต้นไป ",
                            style: GoogleFonts.kanit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24, left: 40,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text('House ${widget.houseId}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                const SizedBox(width: 24),
                // Performance Debug Info
              ],
            ),
          ),

          // ── Immersive Repair Popup ──
          if (_showRepairPopup)
            PointerInterceptor(
              child: AnimatedBuilder(
                animation: _popupAnim,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_popupAnim.value);
                  return Stack(
                    children: [
                      // Frosted backdrop — click to dismiss
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _closePopup,
                          child: Container(
                            color: Colors.black.withOpacity(0.4 * t),
                          ),
                        ),
                      ),
                      // ── Floating Draggable Card ──
                      ValueListenableBuilder<Offset>(
                        valueListenable: _popupOffset,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isDragging,
                          builder: (context, dragging, child) {
                            return _buildRepairPanel(gold, dragging);
                          },
                        ),
                        builder: (context, offset, cachedPanel) {
                          // Base animation offset (sliding in from right)
                          final animDx = 440 * (1 - t);

                          return Positioned(
                            top: 100,
                            right: 40 - animDx,
                            width: 440,
                            bottom: 40,
                            child: Transform.translate(
                              offset: offset,
                              child: t == 1.0 
                                ? _buildDraggableStack(cachedPanel)
                                : Opacity(
                                    opacity: t,
                                    child: _buildDraggableStack(cachedPanel),
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            )
          else if (_selectedObjectName.isNotEmpty)
            _buildMinimizedFab(context, gold),
        ],
      ),
    );
  }

  Widget _buildMinimizedFab(BuildContext context, Color gold) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isFabDragging,
      builder: (context, isDragging, _) {
        return Stack(
          children: [
            // Trash Zone
            if (isDragging)
              ValueListenableBuilder<Offset>(
                valueListenable: _fabOffset,
                builder: (context, offset, _) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final screenWidth = MediaQuery.of(context).size.width;
                  bool isHovered = offset.dy > screenHeight - 180 && 
                                   offset.dx > (screenWidth / 2 - 100) && 
                                   offset.dx < (screenWidth / 2 + 100);

                  return Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isHovered ? 96 : 80,
                        height: isHovered ? 96 : 80,
                        decoration: BoxDecoration(
                          color: isHovered ? Colors.redAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: isHovered ? 3 : 1.5),
                        ),
                        child: Icon(Icons.delete_sweep_rounded, color: Colors.redAccent.withOpacity(0.7), size: isHovered ? 40 : 32),
                      ),
                    ),
                  );
                },
              ),

            // Draggable FAB
            ValueListenableBuilder<Offset>(
              valueListenable: _fabOffset,
              builder: (context, offset, child) {
                return Positioned(
                  top: offset.dy,
                  right: offset.dx,
                  child: PointerInterceptor(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                           _showRepairPopup = true;
                        });
                        _popupAnim.forward(from: 0);
                      },
                      onPanStart: (_) => _isFabDragging.value = true,
                      onPanEnd: (details) {
                        _isFabDragging.value = false;
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.width;
                        bool isHovered = offset.dy > screenHeight - 180 && 
                                         offset.dx > (screenWidth / 2 - 100) && 
                                         offset.dx < (screenWidth / 2 + 100);
                        if (isHovered) {
                          setState(() {
                             _selectedObjectName = '';
                             _titleCtrl.clear();
                             _detailCtrl.clear();
                             _attachedImages.clear();
                             _showSuccess = false;
                          });
                          try { js.context.callMethod('resetCamera'); } catch (e) { print(e); }
                        }
                      },
                      onPanUpdate: (details) {
                        _fabOffset.value = Offset(
                          _fabOffset.value.dx - details.delta.dx,
                          _fabOffset.value.dy + details.delta.dy,
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: Icon(Icons.handyman_rounded, color: gold.withOpacity(0.8), size: 26),
                  ),
                  if (!_showSuccess) // unsubmitted/draft
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade400, // A softer Zen red
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF16161C), width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableStack(Widget? cachedPanel) {
    return Stack(
      children: [
        // The heavy panel is cached and wrapped in a boundary
        Positioned.fill(
          child: RepaintBoundary(child: cachedPanel!),
        ),
        // Dedicated hit-testing zone for dragging, absolute top
        Positioned(
          top: 0, left: 0, right: 0, height: 100,
          child: GestureDetector(
            onPanStart: (_) {
              _isDragging.value = true;
            },
            onPanEnd: (_) {
              _isDragging.value = false;
            },
            onPanCancel: () {
              _isDragging.value = false;
            },
            onPanUpdate: (details) {
              _popupOffset.value += details.delta;
            },
            behavior: HitTestBehavior.opaque, // Opaque block click-through
          ),
        ),
      ],
    );
  }

  Widget _buildRepairPanel(Color gold, bool isDragging) {
    final glowColor = _isUrgent ? Colors.redAccent.shade200 : gold;

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(isDragging ? 0.9 : 0.75),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        gradient: isDragging ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.05), Colors.transparent],
        ),
        boxShadow: isDragging ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REPAIR REQUEST', 
                    style: GoogleFonts.anton(color: gold, fontSize: 28, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Container(width: 60, height: 2, color: gold.withOpacity(0.5)),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _closePopup,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          if (_showSuccess) ...[
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gold.withOpacity(0.1),
                      border: Border.all(color: gold.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.check_circle_outline_rounded, size: 80, color: gold),
                  ),
                  const SizedBox(height: 32),
                  Text('SUCCESS!', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text('Your request has been filed.', style: GoogleFonts.kanit(fontSize: 16, color: Colors.white38)),
                ],
              ),
            ),
            const Spacer(),
          ] else if (_showConfirmation) ...[
            Expanded(child: _buildConfirmationOverlay(glowColor)),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OBJECT', style: GoogleFonts.outfit(fontSize: 12, color: gold.withOpacity(0.7), fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(_titleCtrl.text.isEmpty ? _selectedObjectName : _titleCtrl.text, 
                        style: GoogleFonts.outfit(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: -1)),
                      const SizedBox(height: 40),

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
                      
                      _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : _SubmitAction(
                            onTap: () {
                              if (_titleCtrl.text.trim().isEmpty || _detailCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กรุณาระบุหัวข้อและรายละเอียดปัญหาให้ครบถ้วน', style: GoogleFonts.kanit()), backgroundColor: Colors.redAccent));
                                return;
                              }
                              setState(() => _showConfirmation = true);
                            }, 
                            isUrgent: _isUrgent, 
                            gold: gold
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Center(
            child: Text('SECURE ENCRYPTED FILING', 
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.white24, letterSpacing: 1.5)),
          ),
        ],
      ),
    );

    if (isDragging) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2, color: color.withOpacity(0.4)));
  }

  Widget _buildConfirmationOverlay(Color glowColor) {
    final timeStr = _selectedTime?.format(context) ?? 'Not set';
    final dateStr = _selectedDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(_selectedDate!);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _showConfirmation = false), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70)),
              Text('FINAL REVIEW', style: GoogleFonts.shareTechMono(fontSize: 16, color: Colors.white70, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 24),
          _TactileSlab(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
          ),
          if (_attachedImages.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Evidence Gallery (${_attachedImages.length})', style: GoogleFonts.shareTechMono(color: DashboardTheme.textPale.withOpacity(0.5), fontSize: 13, letterSpacing: 2)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: _attachedImages.length,
                itemBuilder: (context, idx) => _PhotoPreview(path: _attachedImages[idx]),
              ),
            ),
          ],
          const SizedBox(height: 48),
          _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Row(
              children: [
                Expanded(child: _OverlayBtn(label: 'Confirm Submit', color: glowColor, onTap: _executeSubmission)),
              ],
            ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// UI WIDGET COMPONENTS (PORTED FROM SRS FORM)
// ════════════════════════════════════════════════════════════════════

class _PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color activeColor;
  final int maxLines;
  const _PremiumInput({required this.controller, required this.hint, required this.activeColor, this.maxLines = 1});

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
              color: isFocused ? widget.activeColor.withOpacity(0.05) : DashboardTheme.surface, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(
                color: isFocused ? widget.activeColor : (_isHovered ? Colors.white38 : DashboardTheme.border),
                width: isFocused ? 1.5 : 1.0,
              ),
              boxShadow: isFocused ? [
                BoxShadow(color: widget.activeColor.withOpacity(0.2), blurRadius: 12, spreadRadius: 1)
              ] : [],
            ), 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: widget.controller, 
              focusNode: _focusNode,
              maxLines: widget.maxLines, 
              style: GoogleFonts.outfit(fontSize: 17, color: DashboardTheme.textMain), 
              cursorColor: DashboardTheme.textMain,
              decoration: InputDecoration(
                hintText: widget.hint, 
                hintStyle: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textPale), 
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              )
            ),
          );
        }
      ),
    );
  }
}

class _PremiumDropdown extends StatefulWidget {
  final String selected;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onChanged;
  const _PremiumDropdown({required this.selected, required this.items, required this.onChanged});

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
          color: DashboardTheme.surface, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: _isHovered ? Colors.white38 : DashboardTheme.border),
        ), 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.selected.isEmpty ? null : widget.selected, 
            isExpanded: true, 
            dropdownColor: DashboardTheme.surface, 
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: _isHovered ? Colors.white70 : DashboardTheme.textPale), 
            hint: Text('Select Category', style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textPale)),
            items: widget.items.expand((cat) { 
              final g = cat['group'] as String; 
              return (cat['items'] as List<String>).map((i) => DropdownMenuItem(value: '$g: $i', child: Text('$g: $i', style: GoogleFonts.outfit(fontSize: 16, color: DashboardTheme.textMain)))); 
            }).toList(),
            onChanged: (v) => widget.onChanged(v ?? ''),
          )
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
  const _ScheduleTrigger({required this.label, this.value, required this.icon, required this.onTap, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasVal ? activeColor.withOpacity(0.15) : DashboardTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasVal ? activeColor : DashboardTheme.border.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: hasVal ? activeColor : DashboardTheme.textPale.withOpacity(0.2), size: 28),
            const SizedBox(height: 12),
            Text(label.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 11, color: DashboardTheme.textPale.withOpacity(0.5), letterSpacing: 1)),
            Text(value ?? 'Not Set', style: GoogleFonts.outfit(fontSize: 15, color: hasVal ? DashboardTheme.textMain : DashboardTheme.textPale.withOpacity(0.3), fontWeight: hasVal ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white10));
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

class _TactileSlab extends StatelessWidget {
  final Widget child;
  const _TactileSlab({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF131318), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)), BoxShadow(color: Colors.white.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))]),
      child: child,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label; final String value; final bool isRed; final bool isGreen; final bool isBold;
  const _ReviewRow({required this.label, required this.value, this.isRed = false, this.isGreen = false, this.isBold = false});
  @override
  Widget build(BuildContext context) { 
    return Padding(
      padding: const EdgeInsets.only(bottom: 14), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(label, style: GoogleFonts.outfit(color: DashboardTheme.textPale, fontSize: 16)),
          ), 
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value, 
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                color: isRed ? Colors.redAccent : (isGreen ? Colors.greenAccent : DashboardTheme.textSecondary), 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
                fontSize: 17
              )
            )
          )
        ]
      )
    ); 
  }
}

class _OverlayBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap; final bool isOutline;
  const _OverlayBtn({required this.label, required this.color, required this.onTap, this.isOutline = false});
  @override
  Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(height: 60, decoration: BoxDecoration(color: isOutline ? Colors.transparent : color, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), alignment: Alignment.center, child: Text(label, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: isOutline ? DashboardTheme.textPale : Colors.black)))); }
}
