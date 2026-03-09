import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_sidebar.dart';
import '../widgets/floating_repair_panel.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:fcm_app/core/data/auth_repository.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class ModelViewScreen extends StatefulWidget {
  final String username;
  const ModelViewScreen({super.key, this.username = 'Resident'});

  @override
  State<ModelViewScreen> createState() => _ModelViewScreenState();
}

class _ModelViewScreenState extends State<ModelViewScreen> with TickerProviderStateMixin { 
  late AnimationController _controller;
  late Animation<double> _uiOpacityAnim; 

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();

  String _displayUsername = '';

  @override
  void initState() {
    super.initState();
    _displayUsername = widget.username;
    _fetchUserProfile();
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));
    _uiOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)));
    _controller.forward();

    // ── JS INTEROP: V13.0 Flex-Match & Debug Bridge (Detail) ──
    try {
      js.context['onDetailObjectClicked'] = (dynamic name) {
        if (mounted) _handleObjectClick(name);
      };

      js.context['fcmDebugLog'] = (dynamic msg) {
        print("★★★ FCM_DEBUG_DETAIL: $msg ★★★");
      };

      js.context.callMethod('eval', [
        r"""
        (function() {
          // ── V14.0 — Complete Selection & Highlight Rewrite ──
          
          // Helper: find the Three.js scene inside a <model-viewer>
          const getScene = (mv) => {
             const syms = Object.getOwnPropertySymbols(mv);
             for (const s of syms) {
                const v = mv[s];
                if (v && (v.type === 'Scene' || v.scene?.type === 'Scene')) return v.scene || v;
             }
             return null;
          };

          // ── Safe cleanup helper ──
          function fcmCleanupOverlays() {
              if (window._fcmOverlays && window._fcmOverlays.length) {
                  window._fcmOverlays.forEach(ov => {
                      try {
                          if (ov && ov.parent) ov.parent.remove(ov);
                          if (ov && ov.geometry) ov.geometry.dispose();
                          if (ov && ov.material) ov.material.dispose();
                      } catch(_) {}
                  });
              }
              window._fcmOverlays = [];
          }

          // ── Roof toggle (unchanged logic, just cleaner) ──
          window.toggleRoof = function() {
              if (window._fcmMasterVisible === undefined) window._fcmMasterVisible = true;
              window._fcmMasterVisible = !window._fcmMasterVisible;
              const state = window._fcmMasterVisible;
              
              const isProtected = (node) => {
                  let current = node;
                  while (current) {
                      const n = (current.name || '').toLowerCase();
                      if (n.includes('couch') || n.includes('sofa') || n.includes('door') || n.includes('gate') || n.includes('window')) return true;
                      current = current.parent;
                  }
                  return false;
              };

              document.querySelectorAll('model-viewer').forEach(mv => {
                  const scene = getScene(mv);
                  if (!scene) return;
                  scene.traverse(node => {
                      if (isProtected(node)) return;
                      const lname = (node.name || '').toLowerCase().trim();
                      if (lname.includes('cube032') || lname.includes('cube_032') || lname.includes('cube.032') || lname.includes('roof')) {
                          node.visible = state;
                      }
                  });
              });
              window.fcmDebugLog && window.fcmDebugLog('Roof Toggled: ' + state);
          };

          // ── Helper: create a highlight material from an existing mesh ──
          function fcmCreateHighlightMaterial(refMaterial) {
              // Try to construct from the reference material's constructor (works for MeshStandardMaterial, MeshPhongMaterial, etc.)
              try {
                  const Ctor = refMaterial.constructor;
                  const mat = new Ctor({
                      color: 0xff7700,
                      transparent: true,
                      opacity: 0.75,
                      emissive: 0xaa4400,
                      emissiveIntensity: 2.0,
                      depthTest: true,
                      depthWrite: false,
                      polygonOffset: true,
                      polygonOffsetFactor: -4,
                      polygonOffsetUnits: -4,
                      side: 2 // DoubleSide
                  });
                  return mat;
              } catch(_) {
                  // Ultimate fallback — clone material and tint it
                  try {
                      const mat = refMaterial.clone();
                      mat.color && mat.color.setHex(0xff7700);
                      mat.transparent = true;
                      mat.opacity = 0.75;
                      mat.depthWrite = false;
                      return mat;
                  } catch(__) { return null; }
              }
          }

          // ── Helper: create overlay for a single mesh node ──
          function fcmCreateOverlay(meshNode) {
              if (!meshNode || !meshNode.isMesh || !meshNode.geometry) return null;
              try {
                  const refMat = Array.isArray(meshNode.material) ? meshNode.material[0] : meshNode.material;
                  const mat = fcmCreateHighlightMaterial(refMat);
                  if (!mat) return null;
                  
                  const geo = meshNode.geometry; // Share geometry, no need to clone
                  const MeshCtor = meshNode.constructor;
                  const overlay = new MeshCtor(geo, mat);
                  
                  overlay.position.copy(meshNode.position);
                  overlay.quaternion.copy(meshNode.quaternion);
                  overlay.scale.copy(meshNode.scale);
                  overlay.renderOrder = 999;
                  overlay.matrixAutoUpdate = true;
                  
                  if (meshNode.parent) {
                      meshNode.parent.add(overlay);
                      return overlay;
                  }
              } catch(e) {
                  window.fcmDebugLog && window.fcmDebugLog('Overlay error: ' + e);
              }
              return null;
          }

          // ── Main selection system ──
          window.setupFcmSelection = function() {
              document.querySelectorAll('model-viewer').forEach(mv => {
                  if (mv._fcmSelectionV14) return;
                  mv._fcmSelectionV14 = true;
                  
                  mv.addEventListener('click', (event) => {
                      try {
                          // 1. Get exact 3D hit point and material from model-viewer's raycaster
                          const hitData = mv.positionAndNormalFromPoint(event.clientX, event.clientY);
                          const materialObj = mv.materialFromPoint(event.clientX, event.clientY);

                          // Always clean up previous overlays first
                          fcmCleanupOverlays();

                          // Clicked empty space → deselect
                          if (!hitData || !hitData.position || !materialObj) {
                              if (window.onObjectClicked) window.onObjectClicked('');
                              return;
                          }

                          const scene = getScene(mv);
                          if (!scene) return;

                          // Find the internal camera
                          let camera = null;
                          Object.getOwnPropertySymbols(mv).forEach(s => {
                              if (mv[s] && mv[s].camera) camera = mv[s].camera;
                          });
                          if (!camera) return;

                          // 2. Construct a perfect ray from camera → hitPoint
                          const rayOrigin = camera.position.clone();
                          const hitP = hitData.position;
                          const dx = hitP.x - rayOrigin.x;
                          const dy = hitP.y - rayOrigin.y;
                          const dz = hitP.z - rayOrigin.z;
                          const rayLen = Math.sqrt(dx*dx + dy*dy + dz*dz);
                          if (rayLen < 1e-10) return; // degenerate ray
                          const rdx = dx/rayLen, rdy = dy/rayLen, rdz = dz/rayLen;

                          let targetMesh = null;
                          let closestDist = Infinity;

                          // 3. Möller–Trumbore: test every visible triangle in the scene
                          scene.traverse(node => {
                              if (!node.isMesh || !node.material || !node.visible || !node.geometry) return;
                              
                              // Material name filter — only check meshes sharing the clicked material
                              const matName = materialObj.name;
                              let isMatch = false;
                              if (Array.isArray(node.material)) {
                                  isMatch = node.material.some(m => m.name === matName);
                              } else {
                                  isMatch = (node.material.name === matName);
                              }
                              if (!isMatch) return;
                              
                              const nLower = (node.name || '').toLowerCase();
                              if (nLower === 'walls') return;

                              node.updateMatrixWorld(true);
                              const inv = node.matrixWorld.clone().invert();
                              const el = inv.elements;

                              // Transform ray origin & hit point into mesh-local space
                              const loX = rayOrigin.x*el[0] + rayOrigin.y*el[4] + rayOrigin.z*el[8]  + el[12];
                              const loY = rayOrigin.x*el[1] + rayOrigin.y*el[5] + rayOrigin.z*el[9]  + el[13];
                              const loZ = rayOrigin.x*el[2] + rayOrigin.y*el[6] + rayOrigin.z*el[10] + el[14];
                              const ltX = hitP.x*el[0] + hitP.y*el[4] + hitP.z*el[8]  + el[12];
                              const ltY = hitP.x*el[1] + hitP.y*el[5] + hitP.z*el[9]  + el[13];
                              const ltZ = hitP.x*el[2] + hitP.y*el[6] + hitP.z*el[10] + el[14];

                              let ldx = ltX-loX, ldy = ltY-loY, ldz = ltZ-loZ;
                              const lLen = Math.sqrt(ldx*ldx + ldy*ldy + ldz*ldz);
                              if (lLen < 1e-10) return;
                              ldx /= lLen; ldy /= lLen; ldz /= lLen;

                              const pos = node.geometry.attributes.position;
                              if (!pos) return;
                              const arr = pos.array;
                              const idx = node.geometry.index;
                              let minT = Infinity;

                              const checkTri = (i0, i1, i2) => {
                                  const v0x=arr[i0*3],v0y=arr[i0*3+1],v0z=arr[i0*3+2];
                                  const v1x=arr[i1*3],v1y=arr[i1*3+1],v1z=arr[i1*3+2];
                                  const v2x=arr[i2*3],v2y=arr[i2*3+1],v2z=arr[i2*3+2];
                                  const e1x=v1x-v0x,e1y=v1y-v0y,e1z=v1z-v0z;
                                  const e2x=v2x-v0x,e2y=v2y-v0y,e2z=v2z-v0z;
                                  const hx=ldy*e2z-ldz*e2y, hy=ldz*e2x-ldx*e2z, hz=ldx*e2y-ldy*e2x;
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

                              if (idx) {
                                  const iArr=idx.array;
                                  for(let i=0;i<iArr.length;i+=3)checkTri(iArr[i],iArr[i+1],iArr[i+2]);
                              } else {
                                  for(let i=0;i<arr.length/3;i+=3)checkTri(i,i+1,i+2);
                              }

                              if (minT < Infinity) {
                                  // Convert back to world distance for comparison
                                  const hlX=loX+ldx*minT, hlY=loY+ldy*minT, hlZ=loZ+ldz*minT;
                                  const mw=node.matrixWorld.elements;
                                  const hwX=hlX*mw[0]+hlY*mw[4]+hlZ*mw[8]+mw[12];
                                  const hwY=hlX*mw[1]+hlY*mw[5]+hlZ*mw[9]+mw[13];
                                  const hwZ=hlX*mw[2]+hlY*mw[6]+hlZ*mw[10]+mw[14];
                                  const wdx=hwX-rayOrigin.x,wdy=hwY-rayOrigin.y,wdz=hwZ-rayOrigin.z;
                                  const worldDist=Math.sqrt(wdx*wdx+wdy*wdy+wdz*wdz);
                                  if (worldDist < closestDist) {
                                      closestDist = worldDist;
                                      targetMesh = node;
                                  }
                              }
                          });

                          // ★ FIX #1: Null-safe — if no triangle hit, deselect cleanly
                          if (!targetMesh) {
                              if (window.onDetailObjectClicked) window.onDetailObjectClicked('');
                              window.fcmDebugLog && window.fcmDebugLog('คลิกไม่โดนวัตถุใดๆ');
                              return;
                          }

                          // 4. Determine best node (group or single mesh)
                          let bestName = targetMesh.name || 'Mesh';
                          let bestNode = targetMesh;
                          const ignoreGroup = ['scene','target','root','model','wall','floor','ceiling','structure','house','building','outside','walls'];
                          
                          if (targetMesh.parent && targetMesh.parent.name) {
                              const pType = targetMesh.parent.type;
                              if (pType === 'Group' || pType === 'Object3D') {
                                  const pName = targetMesh.parent.name.toLowerCase();
                                  if (!ignoreGroup.some(ig => pName.includes(ig))) {
                                      bestName = targetMesh.parent.name || bestName;
                                      bestNode = targetMesh.parent;
                                  }
                              }
                          }

                          // 5. Create highlight overlay(s)
                          window._fcmOverlays = [];
                          
                          if (bestNode.isMesh) {
                              // Single mesh — highlight just this one
                              const ov = fcmCreateOverlay(bestNode);
                              if (ov) window._fcmOverlays.push(ov);
                          } else {
                              // Group node — highlight all child meshes
                              bestNode.traverse(child => {
                                  if (child.isMesh && child.visible) {
                                      const ov = fcmCreateOverlay(child);
                                      if (ov) window._fcmOverlays.push(ov);
                                  }
                              });
                          }

                          // 6. Notify Dart
                          const displayName = bestName;
                          if (window.onDetailObjectClicked) window.onDetailObjectClicked(displayName);
                          window.fcmDebugLog && window.fcmDebugLog('เลือก: ' + displayName);

                      } catch (e) {
                          window.fcmDebugLog && window.fcmDebugLog('Selection Error: ' + e.toString());
                      }
                  });
              });
          };

          // Initialize: poll until model-viewer appears
          const poll = setInterval(() => {
              if (document.querySelector('model-viewer')) {
                  window.setupFcmSelection();
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
  
  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (mounted && result['success']) {
      setState(() {
         String name = result['data']['name'] ?? 'Resident';
         if (result['data']['houseId'] != null) name += ' (${result['data']['houseId']})';
         _displayUsername = name;
      });
    }
  }
  
  String _formatObjectName(String rawName) {
    final lower = rawName.toLowerCase();
    
    // 1. Detailed specific mapping based on extracted GLB node names
    final Map<String, String> detailedMap = {
      // Structure & Floors
      'plane.778': 'Left Exterior Wall',
      'plane.020': 'Front Exterior Wall',
      'plane.777': 'Interior Wall',
      'floors.001': 'Living Room Floor',
      'floors.002': 'Bedroom Floor',
      'floors.003': 'Kitchen Floor',
      'floors.004': 'Bathroom Floor',
      'floors.005': 'Toilet Floor',
      'floors.006': 'Porch Floor',
      
      // Appliances & Tech
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
      'modern ceiling light 01': 'Ceiling Light',
      'double spot light': 'Spot Light',
      'bollard lighting': 'Bollard Garden Light',
      
      // Furniture
      'couchdouble': 'Sofa (Living)',
      'coffeetable': 'Coffee Table',
      'designer carpet': 'Carpet/Rug',
      'closetr': 'Bedroom Closet',
      'closettv': 'TV Cabinet',
      'nightstand': 'Nightstand',
      'floorcabinet': 'Floor Cabinet',
      'wallcabinet': 'Wall Cabinet',
      'kitchensinkl': 'Kitchen Sink',
      'stover': 'Kitchen Stove',
      
      // Bathroom
      'toilet': 'Toilet',
      'tub': 'Bathtub',
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
        // Keep small words lowercase unless it's the first word
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    
    return cleaned;
  }

  void _handleObjectClick(dynamic rawName) {
    if (rawName is String) {
      // Clear previous queue so it feels instant
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (rawName.isEmpty) return;

      String shortName = rawName.split(' [').first;
      String displayName = _formatObjectName(shortName);

      // Navigate to resident dashboard → REPAIR tab with pre-filled object name
      Navigator.of(context).pushReplacementNamed(
        '/3d_model',
        arguments: {'repairObject': displayName},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: Stack(
                children: [
                AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Opacity(opacity: _uiOpacityAnim.value, child: child),
                    child: Column(
                    children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Row(
                              children: [
                              Text('FCM', style: GoogleFonts.anton(color: const Color(0xFFC5A059), fontSize: 24)),
                              const Spacer(),
                              IconButton(onPressed: () => js.context.callMethod('toggleRoof'), icon: const Icon(Icons.layers, color: Color(0xFFC5A059))),
                              ],
                          ),
                        ),
                        Expanded(
                          child: ModelViewer(
                            key: const ValueKey('fcm_detail_model_stable'),
                            src: 'assets/models/VivornFinal8.4.glb',
                            alt: "FCM 3D House",
                            backgroundColor: Colors.black,
                            exposure: 1.0,
                            loading: Loading.eager,
                            autoRotate: true,
                            cameraControls: true,
                          ),
                        ),
                    ],
                    ),
                ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}
