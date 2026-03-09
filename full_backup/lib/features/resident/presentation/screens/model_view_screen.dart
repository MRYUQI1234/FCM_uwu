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

class ModelViewScreen extends StatefulWidget {
  final String username;
  const ModelViewScreen({super.key, this.username = 'Resident'});

  @override
  State<ModelViewScreen> createState() => _ModelViewScreenState();
}

class _ModelViewScreenState extends State<ModelViewScreen> with TickerProviderStateMixin { 
  // ... (animations) ...
  late AnimationController _controller;
  late Animation<double> _textOpacityAnim;
  late Animation<double> _textScaleAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _uiOpacityAnim; 

  bool _animationFinished = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for Drawer

  // Image Picker
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  // Dialog State
  bool _isDialogOpen = false;
  // Repair Popup Dialog State (separate from panel)
  bool _isRepairPopupOpen = false;
  // Sidebar State
  bool _isSidebarOpen = false;
  // Floating Repair Panel State
  bool _isRepairPanelOpen = false;
  // Pending repair items for the floating panel
  List<PendingRepairItem> _pendingRepairItems = [];

  // User Data
  String _displayUsername = '';

  @override
  void initState() {
    // ... (init)
    super.initState();
    
    // Initialize with widget.username or 'Resident'
    _displayUsername = widget.username;

    // Fetch latest profile from API (if session exists)
    _fetchUserProfile();
    
    // ...
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 5000), 
    );
    // ... (animations defs) ...
    _textOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );
    _textScaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );
    _textSlideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOutQuad)),
    );

    _uiOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );
    
    _controller.forward();
    // ... (JS callbacks) ...
    try {
        js.context['onObjectClicked'] = _handleObjectClick;
    } catch(e) {}
  }
  
  Future<void> _fetchUserProfile() async {
    final result = await AuthRepository.instance.getProfile();
    if (result['success']) {
      final data = result['data'];
      if (mounted) {
        setState(() {
           // Display Name (House ID optionally)
           // If Name is provided use it, otherwise use House ID or Email
           String name = data['name'] ?? 'Resident';
           if (data['houseId'] != null) {
             name += ' (${data['houseId']})';
           }
           _displayUsername = name;
        });
      }
    } else if (result['expired'] == true) {
      // Session Expired logic (from v0.2.3_xx instructions)
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่', style: TextStyle(fontFamily: 'Kanit')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  // ... (handleObjectClick, showRepairDialog) ... (Keep same)
  void _handleObjectClick(dynamic name) {
    print("FCM Dart: Object Clicked -> $name");
    // Prevent opening multiple dialogs/popups at the same time
    if (_isDialogOpen || _isRepairPopupOpen) return;

    if (name is String) {
      _showRepairDialog(name);
    }
  }

  void _showRepairDialog(String objectName) {
    setState(() {
      // Use only _isRepairPopupOpen for repair popup (not _isDialogOpen - that's for sidebar dialogs)
      _isRepairPopupOpen = true;
    });


    showDialog(
      context: context,
      barrierDismissible: true, // Allow click outside to close
      builder: (context) {
        // StatefulBuilder allows us to update the dialog's local state (for image preview)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFC5A059), width: 1),
              ),
              title: Row(
                children: [
                   const Icon(Icons.build_circle, color: Color(0xFFC5A059)),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'แจ้งซ่อม: $objectName', 
                       style: GoogleFonts.kanit(color: const Color(0xFFC5A059), fontWeight: FontWeight.bold),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                ],
              ),
              content: SizedBox(
                width: 400, // Fixed width for desktop/web
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'พบปัญหาที่จุดนี้ใช่ไหม? แจ้งรายละเอียดได้เลย',
                      style: GoogleFonts.kanit(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description Input
                    TextField(
                      autofocus: true, // Focus automatically
                      style: GoogleFonts.kanit(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'รายละเอียดปัญหา...',
                        hintStyle: GoogleFonts.kanit(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFC5A059)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    // Attach Image Button (Functional)
                    InkWell(
                      onTap: () async {
                        try {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setStateDialog(() {
                              _selectedImage = image;
                            });
                          }
                        } catch (e) {
                          print("Image Picker Error: $e");
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black,
                        ),
                        child: _selectedImage != null 
                          ? Column(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                const SizedBox(height: 8),
                                Text(
                                  'แนบรูปแล้ว: ${_selectedImage!.name}',
                                  style: GoogleFonts.kanit(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                                const SizedBox(height: 8),
                                Text(
                                  'คลิกเพื่อแนบรูปภาพ',
                                  style: GoogleFonts.kanit(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset state
                    setState(() {
                      _isRepairPopupOpen = false;
                      _selectedImage = null;
                    });
                    
                    // Clear Highlight in 3D Model
                    try {
                      js.context.callMethod('clearHighlight');
                      js.context.callMethod('toggleInteractable', [true]); // Re-enable interaction
                    } catch (e) {
                      print("JS Error: $e");
                    }
                    
                    Navigator.pop(context);
                  },
                  child: Text('ยกเลิก', style: GoogleFonts.kanit(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add to pending items instead of directly to repository
                    setState(() {
                      _pendingRepairItems.add(PendingRepairItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: objectName,
                        imagePath: _selectedImage?.path,
                      ));
                      _selectedImage = null;
                      _isRepairPanelOpen = true; // Keep panel open
                      _isRepairPopupOpen = false; // Close popup state
                    });
                    
                    // Clear Highlight in 3D Model
                    try {
                      js.context.callMethod('clearHighlight');
                    } catch (e) {
                      print("JS Error: $e");
                    }

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('เพิ่ม "$objectName" ลงในรายการแล้ว', style: GoogleFonts.kanit(color: Colors.white)),
                        backgroundColor: const Color(0xFFC5A059),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: Colors.black,
                  ),
                  child: Text('ส่งเรื่อง', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Ensure state is reset if dialog is dismissed otherwise
      if (_isDialogOpen) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    }); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if arguments were passed via Navigator (for named routes case)
    final args = ModalRoute.of(context)?.settings.arguments;
    // Prefer fetched username (_displayUsername), then args, then widget default
    final displayUser = _displayUsername.isNotEmpty && _displayUsername != 'Resident' 
        ? _displayUsername 
        : (args is String ? args : widget.username);

    return Scaffold(
      key: _scaffoldKey, // Still useful for general scaffold features, but not for this custom drawer
      backgroundColor: Colors.black, // Dark background
      // drawer: CustomSidebar(username: displayUser), // REMOVED standard drawer
      body: Row(
        children: [
          // --- 1. Persistent Sidebar (Animated) ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 350 : 0, // Toggle width
            child: ClipRect( // prevent overflow rendering
              child: OverflowBox( // Allow content to be full width even when container is small (prevents squishing)
                minWidth: 350,
                maxWidth: 350,
                alignment: Alignment.topLeft,
                child: CustomSidebar(
                    username: displayUser,
                    onMenuPressed: () {
                        setState(() {
                            _isSidebarOpen = false; // Close on sidebar menu click
                        });
                    },
                    // SYNC DIALOG STATE
                    onDialogVisibilityChanged: (isOpen) {
                      setState(() {
                        _isDialogOpen = isOpen;
                      });
                    },
                    // NEW: Open floating repair panel (don't block model - allow clicking objects)
                    onNewRepairPressed: () {
                      setState(() {
                        _isRepairPanelOpen = true;
                        // Don't set _isDialogOpen - allow clicking objects to add
                      });
                    },
                ),
              ),
            ),
          ),

          // --- 2. Main Content (Takes remaining space) ---
          Expanded(
            child: Stack(
                children: [
                // --- MAIN UI LAYER (Fades in last) ---
                AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                    return Opacity(
                        opacity: _uiOpacityAnim.value,
                        child: IgnorePointer(
                        ignoring: _uiOpacityAnim.value < 0.9, // Disable interaction until mostly visible
                        child: child,
                        ),
                    );
                    },
                    child: Column(
                    children: [
                        // 1. Custom Header (AppBar replacement)
                        Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        color: Colors.black, // Match background
                        child: Row(
                            children: [
                            // Menu Icon (Only visible if Sidebar is CLOSED)
                            // Or generally always visible to re-open? 
                            // User request: "relative...". 
                            // If sidebar is open, user likely uses sidebar menu icon to close.
                            // If sidebar is closed, this opens it.
                            if (!_isSidebarOpen) ...[
                                IconButton(
                                    icon: const Icon(Icons.menu, color: Color(0xFFC5A059), size: 28),
                                    onPressed: () {
                                         setState(() {
                                             _isSidebarOpen = true; // OPEN
                                         });
                                    },
                                ),
                                const SizedBox(width: 16),
                            ],
                            
                            // Logo & Username
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Text(
                                    'FCM',
                                    style: GoogleFonts.anton(
                                    color: const Color(0xFFC5A059),
                                    fontSize: 24,
                                    letterSpacing: 1.5,
                                    height: 1.0,
                                    ),
                                ),
                                Text(
                                    displayUser.toUpperCase(), // Username Top-Left
                                    style: GoogleFonts.kanit(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                    ),
                                ),
                                ],
                            ),
                            const Spacer(),
                            // Right Side Icons (Layers/View Modes)
                            IconButton(
                                onPressed: () {
                                try {
                                    js.context.callMethod('toggleRoof');
                                } catch (e) {
                                    print("JS Error: $e");
                                }
                                },
                                icon: const Icon(Icons.layers, color: Color(0xFFC5A059), size: 28),
                                tooltip: 'Toggle Roof',
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.view_in_ar, color: Color(0xFFC5A059), size: 28), // Placeholder
                            const SizedBox(width: 16),
                            const Icon(Icons.settings, color: Color(0xFFC5A059), size: 28),
                            ],
                        ),
                        ),

                        // 2. Main Content (3D Model)
                        Expanded(
                        child: Stack(
                            children: [
                            // AbsorbPointer blocks when sidebar dialog or repair popup is open
                            AbsorbPointer(
                              absorbing: _isDialogOpen || _isRepairPopupOpen,
                              child: ModelViewer(
                                src: 'gulli_bulli_house.glb',
                                alt: "A 3D model of the house",
                                ar: true,
                                backgroundColor: Colors.black,
                                skyboxImage: 'skybox.png',
                                environmentImage: 'skybox.png',
                                cameraOrbit: "45deg 55deg 5m",
                                cameraTarget: "0m 0m 0m",
                                exposure: 2.0,
                                shadowIntensity: 0.4,
                                loading: Loading.eager,
                              ),
                            ),
                            // PointerInterceptor blocks when sidebar dialog or repair popup is open
                            if (_isDialogOpen || _isRepairPopupOpen)
                              Positioned.fill(
                                child: PointerInterceptor(
                                  intercepting: true,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {},
                                    onScaleUpdate: (_) {},
                                    child: Container(color: Colors.red.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            // Floating Repair Panel
                            if (_isRepairPanelOpen)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 100,
                                child: FloatingRepairPanel(
                                  pendingItems: _pendingRepairItems,
                                  onRemoveItem: (id) {
                                    setState(() {
                                      _pendingRepairItems.removeWhere((item) => item.id == id);
                                    });
                                  },
                                  onClose: () {
                                    setState(() {
                                      _isRepairPanelOpen = false;
                                      _isDialogOpen = false;
                                      _pendingRepairItems.clear(); // Clear items on cancel
                                    });
                                  },
                                  onSubmit: () {
                                    setState(() {
                                      _isRepairPanelOpen = false;
                                      _isDialogOpen = false;
                                      _pendingRepairItems.clear(); // Clear after submit
                                    });
                                  },
                                ),
                              ),
                            ],
                        ),
                        ),

                        // 3. Bottom AI Assistant Bar
                        Padding(
                        padding: const EdgeInsets.only(left: 40, right: 40, bottom: 40, top: 20),
                        child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                            color: const Color(0xFF151515), // Very dark grey
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: const Color(0xFFC5A059), // Gold Border
                                width: 1,
                            ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                            children: [
                                Expanded(
                                child: Text(
                                    'ถามผู้ช่วย AI', // Ask AI Assistant
                                    style: GoogleFonts.kanit(
                                    color: const Color(0xFFC5A059), // Gold Text
                                    fontSize: 18,
                                    ),
                                ),
                                ),
                            ],
                            ),
                        ),
                        ),
                    ],
                    ),
                ),

                // --- ANIMATION LAYER (Welcome Text) ---
                AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                    // Custom logic for Fade Out based on controller value
                    // 0.0 - 0.2: Fade In
                    // 0.2 - 0.6: Hold
                    // 0.6 - 0.8: Fade Out
                    double opacity = 0.0;
                    if (_controller.value < 0.2) {
                        opacity = _textOpacityAnim.value; // Fading in
                    } else if (_controller.value < 0.6) {
                        opacity = 1.0; // Hold
                    } else if (_controller.value < 0.8) {
                        // Fade out map: 0.6->1.0 to 0.8->0.0
                        opacity = 1.0 - ((_controller.value - 0.6) / 0.2);
                    } else {
                        opacity = 0.0; // Gone
                    }

                    if (opacity <= 0) return const SizedBox.shrink(); // Hide efficiently

                    return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                        offset: _textSlideAnim.value,
                        child: Transform.scale(
                            scale: _textScaleAnim.value,
                            child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Text(
                                    'WELCOME HOME',
                                    style: GoogleFonts.anton(
                                    color: const Color(0xFFC5A059), // Gold
                                    fontSize: 64,
                                    letterSpacing: 4.0,
                                    shadows: [
                                        BoxShadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 20,
                                        spreadRadius: 10,
                                        )
                                    ],
                                    ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                    displayUser.toUpperCase(),
                                    style: GoogleFonts.kanit(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 8.0,
                                    ),
                                ),
                                ],
                            ),
                            ),
                        ),
                        ),
                    );
                    },
                ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}
