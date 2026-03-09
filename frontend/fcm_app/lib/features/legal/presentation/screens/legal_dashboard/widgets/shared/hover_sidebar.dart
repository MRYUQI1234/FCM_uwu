import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class SidebarItem {
  final int index;
  final IconData icon;
  final String label;

  const SidebarItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

class HoverSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onLogout;
  final List<SidebarItem> items;
  final String brandTitle;
  final String brandSubtitle;

  const HoverSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.onLogout,
    required this.items,
    this.brandTitle = "FCM PLATFORM",
    this.brandSubtitle = "ENTERPRISE QUALITY MANAGEMENT",
  });

  @override
  State<HoverSidebar> createState() => _HoverSidebarState();
}

class _HoverSidebarState extends State<HoverSidebar> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _width;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _width = Tween<double>(begin: 80, end: 260).animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOutCubic));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ac, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ac.forward(),
      onExit: (_) => _ac.reverse(),
      child: AnimatedBuilder(
        animation: _ac,
        builder: (context, child) {
          final double currentWidth = _width.value;
          final double expansion = _ac.value;

          return Container(
            width: currentWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: DashboardTheme.background,
              border: Border(right: BorderSide(color: DashboardTheme.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 20, 
                  offset: const Offset(4, 0)
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 48),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: DashboardTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Icon(Icons.security_rounded, color: DashboardTheme.primary)),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: expansion,
                        child: SizedBox(
                          width: 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.brandTitle,
                                style: GoogleFonts.outfit(
                                  color: DashboardTheme.textMain,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                              Text(
                                widget.brandSubtitle,
                                style: GoogleFonts.notoSans(
                                  color: DashboardTheme.textSecondary,
                                  fontSize: 7,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                const SizedBox(height: 60),
                ...widget.items.map((item) => _navItem(
                      item.index,
                      item.icon,
                      item.label,
                      expansion,
                    )),
                const Spacer(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _logoutBtn(expansion),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, double expansion) {
    bool isSelected = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            color: isSelected ? DashboardTheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => widget.onIndexChanged(index),
            mouseCursor: SystemMouseCursors.click,
            hoverColor: DashboardTheme.primary.withOpacity(0.04),
            highlightColor: DashboardTheme.primary.withOpacity(0.08),
            splashColor: DashboardTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 80 - 16,
                    child: Center(
                      child: Icon(
                        icon, 
                        color: isSelected ? DashboardTheme.primary : DashboardTheme.textPale, 
                        size: 20
                      ),
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: expansion,
                      child: SizedBox(
                        width: 160,
                        child: Text(
                          label,
                          style: GoogleFonts.notoSans(
                            color: isSelected ? DashboardTheme.textMain : DashboardTheme.textPale,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
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

  Widget _logoutBtn(double expansion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: DashboardTheme.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: widget.onLogout,
            mouseCursor: SystemMouseCursors.click,
            hoverColor: DashboardTheme.error.withOpacity(0.08),
            highlightColor: DashboardTheme.error.withOpacity(0.1),
            splashColor: DashboardTheme.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 80 - 16,
                    child: Center(
                      child: Icon(Icons.logout_rounded, color: DashboardTheme.error, size: 20),
                    ),
                  ),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: expansion,
                      child: SizedBox(
                        width: 100,
                        child: Text(
                          "LOGOUT",
                          style: GoogleFonts.shareTechMono(
                            color: DashboardTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
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
}
