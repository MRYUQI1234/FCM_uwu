import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JuristicViewScreen extends StatefulWidget {
  const JuristicViewScreen({super.key});

  @override
  State<JuristicViewScreen> createState() => _JuristicViewScreenState();
}

class _JuristicViewScreenState extends State<JuristicViewScreen> {
  int _selectedNavIndex = 0;

  // Design Tokens (Reverted to Light Theme)
  final Color _bgMain = const Color(0xFFF8FAFC);
  final Color _bgSidebar = const Color(0xFFFFFFFF);
  final Color _primaryBlue = const Color(0xFF2563EB); // Admin Blue

  final Color _textMain = const Color(0xFF0F172A);
  final Color _textMuted = const Color(0xFF64748B);
  final Color _border = const Color(0xFFE2E8F0);

  final List<_NavItem> _navItems = [
    _NavItem("แดชบอร์ด", Icons.dashboard_outlined),
    _NavItem("จัดการงานซ่อม", Icons.assignment_outlined),
    _NavItem("รายชื่อช่าง", Icons.people_outline),
    _NavItem("โปรไฟล์", Icons.person_outline),
    _NavItem("ตั้งค่า", Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgMain,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (_selectedNavIndex != 0) _buildHeader(),
                Expanded(
                  child: _selectedNavIndex == 0
                      ? _buildDashboard()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: _buildPageContent(_selectedNavIndex),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _bgSidebar,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.shield, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FCM PLATFORM",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textMain,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      "ENTERPRISE QUALITY MANAGEMENT",
                      style: GoogleFonts.kanit(
                        fontSize: 8,
                        color: _textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _selectedNavIndex == index;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedNavIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _primaryBlue.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isActive ? _primaryBlue : _textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item.title,
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive ? _primaryBlue : _textMuted,
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
          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text("ออกจากระบบ", style: GoogleFonts.kanit()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: _bgSidebar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navItems[_selectedNavIndex].title == "รายชื่อช่าง"
                    ? "รายชื่อช่างเทคนิค"
                    : _navItems[_selectedNavIndex].title == "โปรไฟล์"
                        ? "โปรไฟล์นิติกร"
                        : _navItems[_selectedNavIndex].title == "แดชบอร์ด"
                            ? "แผงควบคุมนิติบุคคล"
                            : _navItems[_selectedNavIndex].title,
                style: GoogleFonts.kanit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textMain),
              ),
              Text(
                _navItems[_selectedNavIndex].title == "รายชื่อช่าง"
                    ? "จัดการรายชื่อและตรวจสอบสถานะการทำงานของช่างในโครงการ"
                    : _navItems[_selectedNavIndex].title == "โปรไฟล์"
                        ? "จัดการข้อมูลส่วนตัวของผู้ดูแลโครงการ"
                        : "ภาพรวมสถานะโครงการหมู่บ้าน Zeta | วันที่ 15 ก.พ. 2569",
                style: GoogleFonts.kanit(fontSize: 14, color: _textMuted),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _bgMain,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text("ค้นหา...",
                        style: GoogleFonts.kanit(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildRequestsPage();
      case 2:
        return _buildTechniciansPage();
      case 3:
        return _buildProfilePage();
      case 4:
        return _buildSettingsPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildProfilePage() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: _card(
          padding: 40,
          child: Column(
            children: [
              // Avatar placeholder as per image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _primaryBlue.withOpacity(0.05), width: 8),
                  color: Colors.white,
                ),
                child: Icon(Icons.person_outline,
                    size: 60, color: _primaryBlue.withOpacity(0.2)),
              ),
              const SizedBox(height: 24),
              Text("Admin Zeta",
                  style: GoogleFonts.kanit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textMain)),
              const SizedBox(height: 4),
              Text("ผู้จัดการโครงการนิติบุคคล (Juristic Person)",
                  style: GoogleFonts.kanit(color: _textMuted)),
              const SizedBox(height: 48),

              _profileRow("ชื่อ-นามสกุล", "Admin Zeta"),
              _profileRow("ตำแหน่ง", "ผู้จัดการนิติบุคคล"),
              _profileRow("เบอร์โทรศัพท์", "080-000-0000",
                  actionLabel: "แก้ไข", onTap: () {}),
              _profileRow("อีเมล", "admin@gmail.com",
                  actionLabel: "แก้ไข", onTap: () {}),
              _profileRow("รหัสผ่าน", "********",
                  actionLabel: "เปลี่ยนรหัส", onTap: () {}),

              const SizedBox(height: 48),

              // Custom Logout inside card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent, size: 18),
                  label: Text("ออกจากระบบ (Admin)",
                      style: GoogleFonts.kanit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          children: [
            _card(
              title: "การตั้งค่าระบบ",
              child: Column(
                children: [
                  _settingsToggle("เปิดรับการแจ้งซ่อมใหม่", true),
                  _settingsToggle("แจ้งเตือนผ่านอีเมลเมื่อมีงานใหม่", true),
                  _settingsToggle("แสดงรายชื่อช่างที่ว่างเท่านั้น", false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _card(
              title: "ความปลอดภัย",
              child: Column(
                children: [
                  ListTile(
                    title: Text("เปลี่ยนรหัสผ่าน", style: GoogleFonts.kanit()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text("ประวัติการเข้าใช้งาน",
                        style: GoogleFonts.kanit()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value,
      {String? actionLabel, VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.kanit(color: _textMuted)),
          Row(
            children: [
              Text(value,
                  style: GoogleFonts.kanit(
                      fontWeight: FontWeight.w600, color: _textMain)),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionLabel,
                      style: GoogleFonts.kanit(
                          color: _primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsToggle(String title, bool val) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.kanit()),
      value: val,
      onChanged: (_) {},
      activeColor: _primaryBlue,
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        // Background Village Visualization
        Positioned.fill(
          child: Image.asset(
            "assets/images/village_map.png",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
                color: _bgMain,
                child: const Center(
                    child: Text("Image Load Error",
                        style: TextStyle(color: Colors.black26)))),
          ),
        ),

        // Gradient for readability (Reduced opacity)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),

        // Floating Markers (matching mockup)
        _floatingMarker(22, 15, "H: B12", "LEAKAGE", Colors.orange),
        _floatingMarker(18, 35, "H: C08", "BROKEN FAUCET", _primaryBlue),
        _floatingMarker(32, 28, "H: A05", "BLACKOUT", Colors.redAccent),

        // Top Header Info (FCM PLATFORM & Weather)
        Positioned(
          top: 32,
          left: 32,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("FCM PLATFORM",
                      style: GoogleFonts.outfit(
                          color: _primaryBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 16)),
                  Text("ENTERPRISE QUALITY MANAGEMENT",
                      style: GoogleFonts.kanit(
                          color: Colors.white60, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          top: 32,
          right: 32,
          child: Row(
            children: [
              _topStatusItem(Icons.sunny, "22°C"),
              const SizedBox(width: 24),
              _topStatusItem(Icons.water_drop, "HUMIDITY 49%"),
              const SizedBox(width: 24),
              _topStatusItem(Icons.air, "WIND 4 KM/H"),
            ],
          ),
        ),

        // Bottom Tech Grid (Categorized)
        Positioned(
          bottom: 32,
          left: 32,
          right: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _techVerticalCard("AIR COND", "RATTANAPHA S.", i: 0),
              _techVerticalCard("ELECTRICAL", "WICHAI V.", i: 1),
              _techVerticalCard("PLUMBING", "KONGKIAT P.", i: 2),
              _techVerticalCard("MASONRY", "APICHAT C.", i: 3, isActive: true),
              _techVerticalCard("PAINTING", "NICHCHA K.", i: 4),
              _techVerticalCard("SYSTEMS", "PEERAPOL M.", i: 5, isActive: true),
              _techVerticalCard("MAINTENANCE", "SATTAWAT L.", i: 6),
            ],
          ),
        ),
      ],
    );
  }

  Widget _floatingMarker(
      double top, double left, String id, String label, Color color) {
    return Positioned(
      top: top * 10, // Approximate positioning
      left: 100 + left * 15,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id,
                    style: GoogleFonts.outfit(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: GoogleFonts.kanit(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),
          Container(width: 1, height: 15, color: color.withOpacity(0.5)),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              id == "H: A05"
                  ? Icons.bolt
                  : (id == "H: B12" ? Icons.water_drop : Icons.build),
              color: color,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topStatusItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: _primaryBlue, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _techVerticalCard(String category, String name,
      {required int i, bool isActive = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF14B8A6)
                : Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(category,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive ? const Color(0xFF2DD4BF) : Colors.white12,
                width: isActive ? 2 : 1),
            image: DecorationImage(
              image: NetworkImage("https://i.pravatar.cc/150?u=tech_$i"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRequestsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("จัดการรายการแจ้งซ่อม",
                    style: GoogleFonts.kanit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _textMain)),
                const SizedBox(height: 4),
                Text("ตรวจสอบและอนุมัติรายการแจ้งซ่อมจากลูกบ้านทั้งหมด",
                    style: GoogleFonts.kanit(color: _textMuted)),
              ],
            ),
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: _bgSidebar,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: TextField(
                style: GoogleFonts.kanit(color: _textMain),
                decoration: InputDecoration(
                  hintText: "หาตามบ้านเลขที่ หรือหัวข้อ...",
                  hintStyle: GoogleFonts.kanit(color: _textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: _textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _card(
          padding: 0,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border))),
                child: Row(
                  children: [
                    _tab("ทั้งหมด (6)", true),
                    const SizedBox(width: 32),
                    _tab("รออนุมัติ (2)", false),
                    const SizedBox(width: 32),
                    _tab("กำลังดำเนินการ (3)", false),
                    const SizedBox(width: 32),
                    _tab("เสร็จสิ้น (1)", false),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: Text("งานส่วนกลาง", style: GoogleFonts.kanit()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                separatorBuilder: (context, i) =>
                    Divider(height: 1, color: _border),
                itemBuilder: (context, i) {
                  // Mock data states as per image
                  int status = 0; // 0=waiting, 1=working, 2=done
                  if (i == 2) status = 1;
                  if (i == 3) status = 2;
                  if (i >= 4) status = 1;

                  return _repairListItem(i, status);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _repairListItem(int i, int status) {
    String title = "ท่อน้ำระเบียงอุดตัน";
    IconData icon = Icons.water_drop_outlined;
    Color iconBg = _primaryBlue.withOpacity(0.1);
    Color iconColor = _primaryBlue;

    String house = "123/45";
    String reporter = "คุณสมชาย";
    String date = "11 ก.พ. 2569";

    if (i == 1) {
      title = "ปลั๊กไฟห้องนอนไหม้";
      icon = Icons.bolt;
      iconBg = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
      house = "105/9";
      reporter = "คุณวิภา";
    } else if (i == 2) {
      title = "หลอดไฟทางเดินขาด";
      icon = Icons.lightbulb_outline;
      iconBg = Colors.amber.withOpacity(0.1);
      iconColor = Colors.amber;
      house = "102/12";
      reporter = "คุณวิจิตร";
      date = "10 ก.พ. 2569";
    } else if (i == 3) {
      title = "ก๊อกน้ำห้องน้ำรั่ว";
      icon = Icons.water_drop_outlined;
      iconBg = _primaryBlue.withOpacity(0.1);
      iconColor = _primaryBlue;
      house = "105/9";
      reporter = "คุณวิภา";
      date = "10 ก.พ. 2569";
    } else if (i == 4) {
      title = "เครื่องทำน้ำอุ่นไม่ร้อน";
      icon = Icons.thermostat;
      iconBg = Colors.orange.withOpacity(0.1);
      iconColor = Colors.orange;
      house = "110/3";
      reporter = "คุณเบญจมา";
      date = "09 ก.พ. 2569";
    } else if (i == 5) {
      title = "ท่อน้ำทิ้งรั่วใต้ซิงค์";
      icon = Icons.water_drop_outlined;
      iconBg = _primaryBlue.withOpacity(0.1);
      iconColor = _primaryBlue;
      house = "108/2";
      reporter = "คุณมานพ";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textMain)),
                const SizedBox(height: 4),
                Text("บ้านเลขที่ $house | แจ้งโดย $reporter | $date",
                    style: GoogleFonts.kanit(fontSize: 14, color: _textMuted)),
              ],
            ),
          ),
          if (status == 0) ...[
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor:
                    const Color(0xFFEF4444).withOpacity(0.7), // Red 500
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text("ปฏิเสธ",
                  style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showAssignModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text("อนุมัติ & มอบหมาย",
                  style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
            ),
          ] else if (status == 1) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("มอบหมายให้: ${i == 2 ? 'ช่างเกรียงไกร' : 'ช่างวิชัย'}",
                    style: GoogleFonts.kanit(
                        fontWeight: FontWeight.w500, color: _textMain)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _border),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("ดูความคืบหน้า",
                      style: GoogleFonts.kanit(
                          color: _textMain, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ] else if (status == 2) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1), // Light Green
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("เสร็จสิ้น",
                      style: GoogleFonts.kanit(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(Icons.star,
                          size: 18, color: const Color(0xFFFBBF24))),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechniciansPage() {
    final techs = [
      {
        "name": "ช่างวิชัย",
        "skill": "ระบบประปา",
        "rating": "4.9",
        "jobs": "127",
        "status": "ว่าง"
      },
      {
        "name": "ช่างเกรียงไกร",
        "skill": "ระบบไฟฟ้า",
        "rating": "4.7",
        "jobs": "89",
        "status": "ติดงาน (1)"
      },
      {
        "name": "ช่างสมหมาย",
        "skill": "งานโครงสร้าง",
        "rating": "4.8",
        "jobs": "56",
        "status": "ว่าง"
      },
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: Text("เพิ่มช่างใหม่", style: GoogleFonts.kanit()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: techs.length,
          separatorBuilder: (context, i) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final tech = techs[i];
            bool isBusy = tech['status']!.contains("ติดงาน");

            return _card(
              padding: 24,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: Icon(Icons.person,
                            color: _primaryBlue.withOpacity(0.5), size: 32),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBusy
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tech['status']!,
                                  style: GoogleFonts.kanit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isBusy
                                          ? Colors.redAccent
                                          : Colors.green)),
                            ),
                            const SizedBox(height: 8),
                            Text(tech['name']!,
                                style: GoogleFonts.kanit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _textMain)),
                            Text("ผู้ชำนาญการ: ${tech['skill']}",
                                style: GoogleFonts.kanit(
                                    color: _textMuted, fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text("${tech['rating']} (${tech['jobs']} งาน)",
                                    style: GoogleFonts.kanit(
                                        fontWeight: FontWeight.w500,
                                        color: _textMain)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.calendar_month_outlined,
                          size: 18, color: _textMuted),
                      label: Text("ดูตารางงาน",
                          style: GoogleFonts.kanit(
                              color: _textMain, fontWeight: FontWeight.w500)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _card(
      {String? title,
      String? subtitle,
      Widget? child,
      double? height,
      bool expand = false,
      double padding = 24}) {
    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textMain)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.kanit(fontSize: 13, color: _textMuted)),
            ],
            const SizedBox(height: 20),
          ],
          if (child != null)
            (height != null || expand) ? Expanded(child: child) : child,
        ],
      ),
    );
  }

  void _showAssignModal(BuildContext context) {
    Set<int> selectedTechIndices = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: _bgSidebar,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _border)),
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("มอบหมายงานช่าง",
                          style: GoogleFonts.kanit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textMain)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: _textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Date box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bgMain,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _primaryBlue.withOpacity(0.1)),
                        color: _bgSidebar,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              color: _textMuted, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("วันที่ลูกบ้านสะดวก:",
                                  style: GoogleFonts.kanit(
                                      color: _textMuted, fontSize: 13)),
                              Text("15 กุมภาพันธ์ 2569",
                                  style: GoogleFonts.kanit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _textMain)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text("เลือกช่างที่จะมอบหมาย (เลือกได้มากกว่า 1 ท่าน)",
                      style: GoogleFonts.kanit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textMain)),
                  const SizedBox(height: 20),
                  // Tech Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: 5,
                    itemBuilder: (context, i) {
                      final techNames = [
                        "ช่างวิชัย",
                        "ช่างเกรียงไกร",
                        "ช่างสมหมาย",
                        "ช่างสถาพร",
                        "ช่างอำนาจ"
                      ];
                      final techSkills = [
                        "ระบบประปา",
                        "ระบบไฟฟ้า",
                        "งานโครงสร้าง",
                        "ระบบแอร์",
                        "งานสี / ตกแต่ง"
                      ];
                      final isBusy = i == 1;
                      final isSelected = selectedTechIndices.contains(i);

                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selectedTechIndices.remove(i);
                            } else {
                              selectedTechIndices.add(i);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryBlue.withOpacity(0.1)
                                : _bgSidebar,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected ? _primaryBlue : _border,
                                width: isSelected ? 2 : 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person,
                                        color: _primaryBlue.withOpacity(0.6),
                                        size: 32),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isBusy
                                            ? Colors.orange
                                            : Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: _bgSidebar, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(techNames[i],
                                  style: GoogleFonts.kanit(
                                      fontWeight: FontWeight.bold,
                                      color: _textMain,
                                      fontSize: 15)),
                              Text(techSkills[i],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.kanit(
                                      color: _textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (selectedTechIndices.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text(
                        "ตรวจสอบความพร้อมของช่างที่เลือก (${selectedTechIndices.length} ท่าน):",
                        style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textMain)),
                    const SizedBox(height: 20),
                    ...selectedTechIndices.toList().map((idx) {
                      final techNames = [
                        "ช่างวิชัย",
                        "ช่างเกรียงไกร",
                        "ช่างสมหมาย",
                        "ช่างสถาพร",
                        "ช่างอำนาจ"
                      ];
                      final techSkills = [
                        "ระบบประปา",
                        "ระบบไฟฟ้า",
                        "งานโครงสร้าง",
                        "ระบบแอร์",
                        "งานสี / ตกแต่ง"
                      ];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _bgSidebar,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                    "ตารางงาน: ${techNames[idx]} (${techSkills[idx]})",
                                    style: GoogleFonts.kanit(
                                        fontWeight: FontWeight.bold,
                                        color: _textMain,
                                        fontSize: 16)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedTechIndices.remove(idx);
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.red.withOpacity(0.05)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text("กุมภาพันธ์ 2569",
                                style: GoogleFonts.kanit(
                                    fontWeight: FontWeight.bold,
                                    color: _textMain)),
                            const SizedBox(height: 16),
                            _buildMiniCalendar(),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _calendarLegend(Colors.redAccent, "มีงาน"),
                                const SizedBox(width: 16),
                                _calendarLegend(Colors.green, "ว่าง"),
                                const SizedBox(width: 16),
                                _calendarLegend(Colors.amber, "วันนัด/เลือก"),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _border,
                            foregroundColor: _textMain,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("ยกเลิก",
                              style: GoogleFonts.kanit(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedTechIndices.isEmpty
                              ? null
                              : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            disabledBackgroundColor:
                                _primaryBlue.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                              selectedTechIndices.length > 1
                                  ? "ยืนยันการมอบหมาย (${selectedTechIndices.length} ท่าน)"
                                  : "ยืนยันการมอบหมาย",
                              style: GoogleFonts.kanit(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
      ],
    );
  }

  Widget _buildMiniCalendar() {
    final days = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"];

    // Mock data for task count and titles
    final Map<int, List<String>> techSchedule = {
      12: ["ซ่อมท่อระเบิด", "ตรวจเช็ควาล์วน้ำ"],
      13: ["ติดตั้งก๊อกน้ำใหม่"],
      18: ["ล้างบ่อบำบัด", "เช็คระบบระบายน้ำ", "เปลี่ยนท่อน้ำทิ้ง"],
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days
              .map((d) => SizedBox(
                  width: 32,
                  child: Center(
                      child: Text(d,
                          style: GoogleFonts.kanit(
                              fontSize: 10, color: _textMuted)))))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 28,
          itemBuilder: (context, i) {
            int day = i + 1;
            bool isSelection = day == 15;
            final dayTasks = techSchedule[day] ?? [];
            bool hasWork = dayTasks.isNotEmpty;
            bool isFree = !hasWork && !isSelection;

            Color bgColor = Colors.transparent;
            Color borderColor = Colors.transparent;
            Color textColor = _textMain;

            if (isSelection) {
              bgColor = const Color(0xFFFEFCE8);
              borderColor = Colors.amber;
            } else if (isFree) {
              bgColor = const Color(0xFFF0FDF4);
              textColor = const Color(0xFF16A34A);
            } else if (hasWork) {
              bgColor = const Color(0xFFFEF2F2);
              textColor = const Color(0xFFEF4444);
            }

            Widget dayWidget = Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("$day",
                        style: GoogleFonts.kanit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    if (hasWork)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          dayTasks.length,
                          (index) => Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );

            if (hasWork) {
              return Tooltip(
                message: "งานวันนี้:\n• ${dayTasks.join('\n• ')}",
                textStyle: GoogleFonts.kanit(color: Colors.white, fontSize: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _textMain.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: dayWidget,
              );
            }

            return dayWidget;
          },
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, String trend, Color color) {
    return _card(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: GoogleFonts.kanit(fontSize: 13, color: _textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _textMain)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trend,
                    style: GoogleFonts.kanit(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.kanit(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(time,
                    style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.kanit(
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? _primaryBlue : _textMuted,
            )),
        if (active) ...[
          const SizedBox(height: 8),
          Container(width: 40, height: 2, color: _primaryBlue),
        ],
      ],
    );
  }

  Widget _techStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, color: _textMain)),
      ],
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  _NavItem(this.title, this.icon);
}
