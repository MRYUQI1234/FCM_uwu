import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/features/chat/presentation/widgets/ai_chat_panel.dart';
import 'package:fcm_app/core/services/translation_service.dart';
// ═══════════════════════════════════════════════════════════
// Resident Home — Premium Always-On Display
// Full-bleed 3D model + TV news-style ticker announcements
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
    with SingleTickerProviderStateMixin {
  // ── Clock ──
  late Timer _clockTimer;
  String _timeStr = '';
  String _dateStr = '';
  String _greeting = '';

  // ── Ticker ──
  late AnimationController _tickerAnim;
  bool _showTicker = true;

  // ── AI Chat ──
  bool _showAIChatPanel = false;

  // Sample announcements
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

    _tickerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _tickerAnim.dispose();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour;
    setState(() {
      _timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _dateStr = _formatDate(now);
      _greeting = hour < 12
          ? 'Good Morning'
          : hour < 17
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

  @override
  Widget build(BuildContext context) {
    final gold = DashboardTheme.primary;

    return Container(
      color: const Color(0xFF0A0A0F),
      child: Stack(
        children: [
          // ── Static 3D Model (Interaction Disabled) ──
          const Positioned.fill(
            child: IgnorePointer(
              child: ModelViewer(
                src: 'assets/models/house.glb',
                alt: 'FCM House Model',
                autoRotate: false,
                autoPlay: true,
                cameraControls: false,
                backgroundColor: Colors.transparent,
                exposure: 0.9,
                shadowIntensity: 0.4,
                shadowSoftness: 1.0,
                cameraTarget: 'auto 1.2m auto',
                cameraOrbit: '45deg 60deg 90%',
              ),
            ),
          ),

          // ── Ambient vignette overlay ──
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0A0A0F).withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Top edge fade ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A0F).withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom edge fade ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF0A0A0F).withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Header: Hamburger + Greeting + Clock ──
          Positioned(
            top: 32,
            left: 40,
            right: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hamburger in-flow
                if (widget.onMenuTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2),
                    child: GestureDetector(
                      onTap: widget.onMenuTap,
                      child: Icon(Icons.menu_rounded, color: gold, size: 28),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting,',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: gold.withOpacity(0.8),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.displayUser,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w200,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateStr,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.45),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── News Ticker (bottom bar) ──
          if (_showTicker)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildNewsTicker(gold),
            ),

          if (!_showTicker)
            Positioned(
              bottom: 24,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showTicker = true),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_rounded, color: gold, size: 14),
                        const SizedBox(width: 6),
                        Text('NEWS',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: gold,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── AI Assistant FAB — hides when panel is open ──
          if (!_showAIChatPanel)
            Positioned(
              bottom: _showTicker ? 72 : 80,
              right: 24,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: () {
                    setState(() => _showAIChatPanel = !_showAIChatPanel);
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Hero(
                    tag: 'ai_assistant_fab',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gold, DashboardTheme.accentAmber],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'V',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            TranslationService.instance.t('ai_chat_fab'),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Floating AI Chat Panel — replaces FAB when open ──
          if (_showAIChatPanel)
            Positioned(
              bottom: _showTicker ? 72 : 32,
              right: 24,
              child: AIChatPanel(
                residentName: widget.displayUser,
                onClose: () => setState(() => _showAIChatPanel = false),
                onHistoryRequested: () {
                  setState(() => _showAIChatPanel = false);
                  if (widget.onHistoryRequested != null) {
                    widget.onHistoryRequested!();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsTicker(Color gold) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.85),
        border: Border(top: BorderSide(color: gold.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          // Label badge
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gold.withOpacity(0.2), gold.withOpacity(0.05)],
              ),
              border: Border(right: BorderSide(color: gold.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, color: gold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'NEWS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: gold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Scrolling text
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _tickerAnim,
                builder: (context, child) {
                  final textStyle = GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w400);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate the width of one set of announcements
                      double itemWidth = 0;
                      for (var a in _announcements) {
                        // Increased buffer to 100 for Icon/Space/Padding/Dot safety
                        itemWidth += _measureText(a.text, textStyle) + 100;
                      }

                      // Add a small safety margin for font rendering variations
                      itemWidth += 50;

                      final totalWidth = itemWidth * 2;
                      final offset = _tickerAnim.value * itemWidth;

                      return Transform.translate(
                        offset: Offset(constraints.maxWidth - offset, 0),
                        child: SizedBox(
                          width: totalWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ..._announcements,
                              ..._announcements,
                            ]
                                .expand((a) => [
                                      Icon(a.icon, color: a.color, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        a.text,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withOpacity(0.65),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: Text(
                                          '●',
                                          style: TextStyle(
                                              color: gold.withOpacity(0.3),
                                              fontSize: 8),
                                        ),
                                      ),
                                    ])
                                .toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _showTicker = false),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.close_rounded,
                    color: Colors.white.withOpacity(0.3), size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }
}

// ───────────────────────────────────────
// Status Pill
// ───────────────────────────────────────

// ───────────────────────────────────────
// Announcement data class
// ───────────────────────────────────────
class _Announcement {
  final IconData icon;
  final Color color;
  final String text;

  const _Announcement({
    required this.icon,
    required this.color,
    required this.text,
  });
}
