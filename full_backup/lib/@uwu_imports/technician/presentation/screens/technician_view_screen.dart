import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicianViewScreen extends StatefulWidget {
  const TechnicianViewScreen({super.key});

  @override
  State<TechnicianViewScreen> createState() => _TechnicianViewScreenState();
}

class _TechnicianViewScreenState extends State<TechnicianViewScreen> {
  int _selectedNavIndex = 0;
  String _selectedTaskFilter = "ทั้งหมด";
  Map<String, String>? _selectedTask;
  int _selectedCalendarDay = 12;
  final String _techName = "ช่างวิชัย";

  // Design Tokens (Light Theme Refined)
  final Color _bgMain = const Color(0xFFF8FAFC);
  final Color _bgSidebar = const Color(0xFFFFFFFF);
  final Color _primaryBlue = const Color(0xFF2563EB);
  final Color _gold =
      const Color(0xFFB8860B); // More professional gold for text/borders
  final Color _textMain = const Color(0xFF0F172A);
  final Color _textMuted = const Color(0xFF64748B);
  final Color _border = const Color(0xFFE2E8F0);

  final List<_NavItem> _navItems = [
    _NavItem("รายการงาน", Icons.assignment_outlined),
    _NavItem("ตารางงาน", Icons.calendar_month_outlined),
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
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
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
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build, color: _primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  "FCM PLATFORM",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                  ),
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
                foregroundColor: _textMuted,
                side: BorderSide(color: _border),
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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _navItems[_selectedNavIndex].title == "รายการงาน"
                    ? "งานที่ได้รับมอบหมาย"
                    : _navItems[_selectedNavIndex].title,
                style: GoogleFonts.kanit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _textMain),
              ),
              Text(
                "สวัสดี $_techName | วันนี้คุณมี 3 งานที่ต้องดำเนินการ",
                style: GoogleFonts.kanit(fontSize: 14, color: _textMuted),
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
        if (_selectedTask != null) {
          return _buildTaskDetailView(_selectedTask!);
        }
        return _buildTasksPage();
      case 1:
        return _buildCalendarPage();
      case 2:
        return _buildProfilePage();
      case 3:
        return _buildSettingsPage();
      default:
        return _buildTasksPage();
    }
  }

  Widget _buildProfilePage() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _card(
          title: "ข้อมูลโปรไฟล์ช่าง",
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFD4AF37),
                child:
                    Icon(Icons.engineering, size: 50, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 24),
              Text(_techName,
                  style: GoogleFonts.kanit(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text("ช่างเทคนิคอาวุโส | ระบบประปาและสุขาภิบาล",
                  style: GoogleFonts.kanit(color: _textMuted)),
              const SizedBox(height: 32),
              _profileRow("รหัสพนักงาน", "TECH-042"),
              _profileRow("อีเมล", "technician@gmail.com"),
              _profileRow("ความเชี่ยวชาญ", "ระบบประปา, ระบบปั๊มน้ำ"),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                    foregroundColor: _gold,
                    side: BorderSide(color: _gold)),
                child: Text("แก้ไขข้อมูลส่วนตัว", style: GoogleFonts.kanit()),
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
              title: "การตั้งค่าการทำงาน",
              child: Column(
                children: [
                  _settingsToggle("เปิดรับงานซ่อมใหม่", true),
                  _settingsToggle("แจ้งเตือนงานด่วน", true),
                  _settingsToggle("แสดงตำแหน่งบนแผนที่นิติ", true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _card(
              title: "บัญชีและความปลอดภัย",
              child: Column(
                children: [
                  ListTile(
                    title: Text("เปลี่ยนรหัสผ่าน", style: GoogleFonts.kanit()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text("ตั้งค่าโหมดมืด (Dark Mode)",
                        style: GoogleFonts.kanit()),
                    trailing: Switch(value: true, onChanged: (_) {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.kanit(color: _textMuted)),
          Text(value,
              style: GoogleFonts.kanit(
                  fontWeight: FontWeight.w600, color: _textMain)),
        ],
      ),
    );
  }

  Widget _settingsToggle(String title, bool val) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.kanit()),
      value: val,
      onChanged: (_) {},
      activeColor: _gold,
    );
  }

  Widget _buildTasksPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip Filters (Matched Mockup)
        Row(
          children: [
            _filterChip("ทั้งหมด", _selectedTaskFilter == "ทั้งหมด"),
            const SizedBox(width: 16),
            _filterChip("กำลังทำ", _selectedTaskFilter == "กำลังทำ"),
            const SizedBox(width: 16),
            _filterChip("รอดำเนินการ", _selectedTaskFilter == "รอดำเนินการ"),
            const SizedBox(width: 16),
            _filterChip("สำเร็จแล้ว", _selectedTaskFilter == "สำเร็จแล้ว"),
          ],
        ),
        const SizedBox(height: 32),
        // Task Grid
        (() {
          final tasks = [
            {
              "title": "ท่อน้ำระเบียงอุดตัน",
              "house": "123/45",
              "status": "working",
              "statusText": "กำลังทำ"
            },
            {
              "title": "ก๊อกน้ำห้องน้ำรั่ว",
              "house": "105/9",
              "status": "pending",
              "statusText": "รอดำเนินการ"
            },
            {
              "title": "หลอดไฟทางเดินขาด",
              "house": "110/3",
              "status": "done",
              "statusText": "สำเร็จแล้ว"
            },
          ];

          final filteredTasks = tasks.where((t) {
            if (_selectedTaskFilter == "ทั้งหมด") return true;
            return t['statusText'] == _selectedTaskFilter;
          }).toList();

          if (filteredTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text("ไม่มีงานในหมวดหมู่นี้",
                    style: GoogleFonts.kanit(color: _textMuted)),
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: filteredTasks.length,
            itemBuilder: (context, i) {
              return _techWorkCard(filteredTasks[i]);
            },
          );
        }()),
      ],
    );
  }

  Widget _buildCalendarPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text("ตารางงานของคุณ",
            style: GoogleFonts.kanit(
                fontSize: 28, fontWeight: FontWeight.bold, color: _textMain)),
        const SizedBox(height: 8),
        Text("ตรวจสอบตารางการนัดหมายและวางแผนการทำงาน",
            style: GoogleFonts.kanit(fontSize: 14, color: _textMuted)),
        const SizedBox(height: 32),

        // Main Calendar Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Grid (Left)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Text("กุมภาพันธ์ 2569",
                        style: GoogleFonts.kanit(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildCalendarGrid(),
                    const SizedBox(height: 24),
                    _buildCalendarLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Day Details (Right)
            SizedBox(
              width: 350,
              child: _buildDayDetailCard(),
            ),
          ],
        ),
        const SizedBox(height: 40),
        // Upcoming Section
        Text("รายการที่ใกล้ถึงกำหนด",
            style: GoogleFonts.kanit(
                fontSize: 20, fontWeight: FontWeight.bold, color: _textMain)),
        const SizedBox(height: 16),
        _buildUpcomingList(),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final days = ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: days
              .map((d) => Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                      child: Text(d,
                          style: GoogleFonts.kanit(
                              fontSize: 12, color: _textMuted)))))
              .toList(),
        ),
        const SizedBox(height: 12),
        // Calendar Rows (Simplified for Feb 2026 starts on Sunday)
        for (var i = 0; i < 4; i++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 1; j <= 7; j++) ...[
                _calendarDay(i * 7 + j),
                if (j < 7) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _calendarDay(int day) {
    bool isSelected = _selectedCalendarDay == day;
    bool isBusy = (day == 13 || day == 18);
    bool isAvailable = !isBusy && !isSelected;

    Color bg = Colors.white;
    Color textColor = _textMain;
    BoxBorder border = Border.all(color: Colors.transparent);

    if (isSelected) {
      bg = const Color(0xFFFFF7ED); // Amber 50
      textColor = const Color(0xFFD97706); // Amber 600
      border = Border.all(color: const Color(0xFFF59E0B), width: 2);
    } else if (isBusy) {
      bg = const Color(0xFFFEF2F2); // Red 50
      textColor = const Color(0xFFDC2626); // Red 600
    } else if (isAvailable) {
      bg = const Color(0xFFECFDF5); // Green 50
      textColor = const Color(0xFF059669); // Green 600
    }

    return InkWell(
      onTap: () => setState(() => _selectedCalendarDay = day),
      child: Container(
        width: 60,
        height: 48,
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
            if (isBusy || isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.red,
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
        _legendItem("มีงาน", Colors.red),
        const SizedBox(width: 16),
        _legendItem("ว่าง", const Color(0xFF059669)),
        const SizedBox(width: 16),
        _legendItem("วันนัด/เลือก", const Color(0xFFF59E0B)),
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

  Widget _buildDayDetailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, style: BorderStyle.solid),
        // Dashed border effect can be simulated via a custom painter if needed,
        // but for now, we'll use a clean solid border or custom opacity.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ตารางงานวันที่",
              style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
          Text("$_selectedCalendarDay กุมภาพันธ์ 2569",
              style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706))),
          const SizedBox(height: 24),
          if (_selectedCalendarDay == 12)
            _compactTaskTile("ซ่อมท่อน้ำประปารั่ว ห้อง 201", "กำลังซ่อม")
          else if (_selectedCalendarDay == 13)
            _compactTaskTile("ล้างถังพักน้ำส่วนกลาง", "รอดำเนินการ")
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text("ไม่มีงานในวันพุธนี้",
                    style: GoogleFonts.kanit(color: _textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactTaskTile(String title, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _gold, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              Text("#---",
                  style: GoogleFonts.outfit(color: _textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold, color: _textMain)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.home_outlined, size: 12, color: _textMuted),
              const SizedBox(width: 4),
              Text("บ้านเลขที่ ---",
                  style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList() {
    final items = [
      {"title": "ล้างถังพักน้ำส่วนกลาง", "date": "13 กุมภาพันธ์ 2569"},
      {"title": "เปลี่ยนก๊อกน้ำสนาม", "date": "18 กุมภาพันธ์ 2569"},
    ];

    return Column(
      children: items.map((it) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it['title']!,
                        style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold, color: _textMain)),
                    Text(it['date']!,
                        style:
                            GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _textMuted),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTaskDetails(Map<String, String> task) {
    setState(() => _selectedTask = task);
  }

  Widget _buildTaskDetailView(Map<String, String> task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Nav & Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedTask = null),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 16, color: _textMuted),
                      const SizedBox(width: 8),
                      Text("กลับหน้าหลัก",
                          style: GoogleFonts.kanit(color: _textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(task['title']!,
                    style: GoogleFonts.kanit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _textMain)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(task['statusText']!,
                  style: GoogleFonts.kanit(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // 3D View Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers_outlined,
                                    color: _gold, size: 20),
                                const SizedBox(width: 8),
                                Text("พื้นที่ซ่อมแซม (3D View)",
                                    style: GoogleFonts.kanit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ],
                            ),
                            Text("บ้านเลขที่ ${task['house']}",
                                style: GoogleFonts.kanit(color: _textMuted)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 400,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.view_in_ar_outlined,
                                        size: 64,
                                        color: _gold.withOpacity(0.3)),
                                    const SizedBox(height: 16),
                                    Text("[ 3D Model Loading... ]",
                                        style: GoogleFonts.kanit(
                                            color: _textMuted)),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10)
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      Text("จุดแจ้งซ่อม: ${task['title']}",
                                          style:
                                              GoogleFonts.kanit(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("รายละเอียดความเสียหาย",
                            style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                        Text("ไม่มีรายละเอียดเพิ่มเติม",
                            style: GoogleFonts.kanit(color: _textMuted)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _bgMain,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("ผู้แจ้งซ่อม",
                                        style: GoogleFonts.kanit(
                                            fontSize: 12, color: _textMuted)),
                                    const SizedBox(height: 4),
                                    Text("คุณบุญมา",
                                        style: GoogleFonts.kanit(
                                            fontWeight: FontWeight.bold)),
                                    Text("08x-xxx-xxxx",
                                        style: GoogleFonts.kanit(
                                            fontSize: 12, color: _textMuted)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _bgMain,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("วันเวลาที่นัดหมาย",
                                        style: GoogleFonts.kanit(
                                            fontSize: 12, color: _textMuted)),
                                    const SizedBox(height: 4),
                                    Text("2026-02-12",
                                        style: GoogleFonts.kanit(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column
            SizedBox(
              width: 350,
              child: Column(
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("สถานะงาน",
                            style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 24),
                        _stepper([
                          _StepData("มอบหมายงาน",
                              "ได้รับมอบหมายเมื่อ 09 ก.พ. 2569", true),
                          _StepData(
                              "กำลังดำเนินการ",
                              "ช่างกำลังเดินทาง/เข้าซ่อม",
                              task['status'] == 'working'),
                          _StepData("เสร็จสิ้น", "รอการประเมินจากลูกบ้าน",
                              task['status'] == 'done'),
                        ]),
                        const SizedBox(height: 32),
                        Divider(color: _border),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF10B981), // Emerald 500
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text("บันทึกงานเสร็จสมบูรณ์",
                              style: GoogleFonts.kanit(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Report Note Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("บันทึกรายงาน",
                            style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "ระบุรายละเอียดการซ่อม...",
                            hintStyle: GoogleFonts.kanit(
                                fontSize: 14, color: _textMuted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _border),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: _border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("บันทึกโน้ต",
                              style: GoogleFonts.kanit(
                                  color: _textMain,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _card({
    String? title,
    Widget? child,
    bool expand = false,
    double padding = 24,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
            const SizedBox(height: 20),
          ],
          if (child != null) expand ? Expanded(child: child) : child,
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active) {
    return InkWell(
      onTap: () => setState(() => _selectedTaskFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primaryBlue : Colors.white,
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

  Widget _techWorkCard(Map<String, String> t) {
    String category = "ระบบประปา";
    if (t['title']!.contains("ไฟ")) category = "ระบบไฟฟ้า";

    Color statusColor = Colors.orange;
    if (t['status'] == 'working') statusColor = _primaryBlue;
    if (t['status'] == 'done') statusColor = Colors.green;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9DB), // Light Yellow
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(category,
                    style: GoogleFonts.kanit(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t['statusText']!,
                    style: GoogleFonts.kanit(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t['title']!,
              style: GoogleFonts.kanit(
                  fontSize: 20, fontWeight: FontWeight.bold, color: _textMain)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.home_outlined, size: 16, color: _textMuted),
              const SizedBox(width: 8),
              Text("บ้านเลขที่ ${t['house']}",
                  style: GoogleFonts.kanit(color: _textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: _textMuted),
              const SizedBox(width: 8),
              Text(
                  "นัดหมาย: 2026-02-${t['status'] == 'working' ? '12' : (t['status'] == 'done' ? '10' : '11')}",
                  style: GoogleFonts.kanit(color: _textMuted)),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: _border),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showTaskDetails(t),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: _gold.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("ดูรายละเอียดและเริ่มงาน",
                style: GoogleFonts.kanit(
                    color: _gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.kanit(color: _textMuted)),
          ),
          Text(value, style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _stepper(List<_StepData> steps) {
    return Column(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: s.done
                        ? (i == steps.length - 1 ? Colors.green : _gold)
                        : Colors.transparent,
                    border: Border.all(
                        color: s.done ? Colors.transparent : _border, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: s.done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (i < steps.length - 1)
                  Container(width: 2, height: 30, color: _border),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: GoogleFonts.kanit(
                        fontWeight: FontWeight.bold,
                        color: s.done ? _textMain : _textMuted)),
                Text(s.sub,
                    style: GoogleFonts.kanit(fontSize: 12, color: _textMuted)),
              ],
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  _NavItem(this.title, this.icon);
}

class _StepData {
  final String title;
  final String sub;
  final bool done;
  _StepData(this.title, this.sub, this.done);
}
