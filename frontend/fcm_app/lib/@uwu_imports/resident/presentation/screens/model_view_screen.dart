import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class ModelViewScreen extends StatefulWidget {
  final String username;
  const ModelViewScreen({super.key, this.username = 'Resident'});

  @override
  State<ModelViewScreen> createState() => _ModelViewScreenState();
}

class _ModelViewScreenState extends State<ModelViewScreen> {
  // Zeta V5.0 Design Tokens
  static const Color _primary = Color(0xFF2563EB);
  static const Color _bgMain = Color(0xFFF8FAFC);
  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _textMain = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const double _radius = 12.0;

  int _selectedNavIndex = 0;
  String _displayUsername = '';

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'หน้าหลัก'),
    _NavItem(icon: Icons.build_outlined, label: 'แจ้งซ่อม'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'ประวัติการซ่อม'),
    _NavItem(icon: Icons.person_outline, label: 'โปรไฟล์'),
    _NavItem(icon: Icons.settings_outlined, label: 'ตั้งค่า'),
  ];

  final List<_Announcement> _announcements = [
    _Announcement(
      date: '15 ก.พ. 2569',
      dateBg: Color(0xFFEFF6FF),
      dateColor: Color(0xFF2563EB),
      title: 'ล้างแท็งก์น้ำส่วนกลาง',
      desc: 'จะมีการปิดน้ำชั่วคราวเวลา 09:00 - 12:00 น.',
    ),
    _Announcement(
      date: '20 ก.พ. 2569',
      dateBg: Color(0xFFFFF7ED),
      dateColor: Color(0xFFC2410C),
      title: 'ฉีดพ่นยากำจัดยุง',
      desc: 'กรุณาปิดหน้าต่างและประตูบ้านให้มิดชิด',
    ),
    _Announcement(
      date: '25 ก.พ. 2569',
      dateBg: Color(0xFFF0FDF4),
      dateColor: Color(0xFF166534),
      title: 'ประชุมใหญ่สามัญประจำปี',
      desc: 'ณ สโมสรส่วนกลาง เวลา 18:00 น. เป็นต้นไป',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _displayUsername = widget.username;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final displayUser =
        _displayUsername.isNotEmpty && _displayUsername != 'Resident'
            ? _displayUsername
            : (args is String ? args : widget.username);

    return Scaffold(
      backgroundColor: _bgMain,
      body: Row(
        children: [
          _buildSidebar(displayUser),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildPageContent(_selectedNavIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildRepairPage();
      case 2:
        return _buildHistoryPage();
      case 3:
        return _buildProfilePage();
      case 4:
        return _buildSettingsPage();
      default:
        return _buildHomePage();
    }
  }

  // --- Page Content Methods ---

  Widget _buildHomePage() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _build3DCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildAnnouncementsCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _build3DCard(),
                    const SizedBox(height: 24),
                    _buildAnnouncementsCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRepairPage() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
              'แจ้งซ่อม', 'จัดการคำขอแจ้งซ่อมและตรวจสอบสถานะการรับประกัน'),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRepairForm()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRepairStatus()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRepairForm(),
                    const SizedBox(height: 24),
                    _buildRepairStatus(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
          _buildFurnitureSection(),
        ],
      ),
    );
  }

  Widget _buildHistoryPage() {
    final historyData = [
      {
        'date': '10 ก.พ. 2569',
        'category': 'ห้องน้ำ',
        'title': 'ท่อระบายน้ำอุดตัน',
        'status': 'กำลังดำเนินการ',
        'color': Color(0xFFF59E0B),
        'reviewed': false
      },
      {
        'date': '5 ก.พ. 2569',
        'category': 'ห้องนั่งเล่น',
        'title': 'เครื่องปรับอากาศไม่เย็น',
        'status': 'รออนุมัติ',
        'color': Color(0xFF6366F1),
        'reviewed': false
      },
      {
        'date': '1 ก.พ. 2569',
        'category': 'ห้องนั่งเล่น',
        'title': 'หลอดไฟห้องนั่งเล่น',
        'status': 'เสร็จสิ้น',
        'color': Color(0xFF10B981),
        'reviewed': true
      },
    ];

    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
              'ประวัติการซ่อม', 'ตรวจสอบรายการแจ้งซ่อมที่ผ่านมาทั้งหมด'),
          const SizedBox(height: 32),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รายการประวัติหมู่บ้าน',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textMain)),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyData.length,
                  separatorBuilder: (context, i) => Divider(color: _border),
                  itemBuilder: (context, i) {
                    final d = historyData[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(d['date'] as String,
                                  style: GoogleFonts.outfit(
                                      fontSize: 13, color: _textMuted))),
                          Expanded(
                              flex: 2,
                              child: Text(d['title'] as String,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textMain))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: (d['color'] as Color).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(d['status'] as String,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: d['color'] as Color)),
                          ),
                        ],
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

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
              'โปรไฟล์ส่วนตัว', 'จัดการข้อมูลและบัญชีผู้ใช้ของคุณ'),
          const SizedBox(height: 32),
          _card(
            child: Column(
              children: [
                CircleAvatar(
                    radius: 50,
                    backgroundColor: _primary,
                    child: Text('ส',
                        style: GoogleFonts.outfit(
                            fontSize: 36, color: Colors.white))),
                const SizedBox(height: 16),
                Text('สมชาย รักดี',
                    style: GoogleFonts.outfit(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 32),
                _profileRow('บ้านเลขที่', '123/45'),
                _profileRow('เบอร์โทรศัพท์', '081-234-5678'),
                _profileRow('อีเมล', 'somchai.r@email.com'),
                const SizedBox(height: 24),
                OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text('ออกจากระบบ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader('ตั้งค่า', 'ปรับแต่งประสบการณ์การใช้งาน'),
          const SizedBox(height: 32),
          _card(
            child: Column(
              children: [
                _settingsToggle('การแจ้งเตือนประกาศ', true),
                _settingsToggle('การแจ้งเตือนสถานะซ่อม', true),
                Divider(color: _border),
                _settingsDropdown('ระดับกราฟิก 3D', 'สูง'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ยินดีต้อนรับสู่บ้านของคุณ',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('บ้านเลขที่ 123/45 | สถานะ: ปกติ',
          style: GoogleFonts.outfit(fontSize: 14, color: _textMuted)),
    ]);
  }

  Widget _buildSidebar(String user) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
          color: _bgCard, border: Border(right: BorderSide(color: _border))),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.home, color: Colors.white)),
              const SizedBox(width: 12),
              Text('FCM PLATFORM',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ])),
        Expanded(
            child: ListView.builder(
          itemCount: _navItems.length,
          itemBuilder: (context, i) => ListTile(
            leading: Icon(_navItems[i].icon,
                color: i == _selectedNavIndex ? _primary : _textMuted),
            title: Text(_navItems[i].label,
                style: GoogleFonts.outfit(
                    color: i == _selectedNavIndex ? _primary : _textMuted)),
            onTap: () => setState(() => _selectedNavIndex = i),
            selected: i == _selectedNavIndex,
            selectedTileColor: _primary.withOpacity(0.05),
          ),
        )),
      ]),
    );
  }

  Widget _build3DCard() {
    return _card(
        height: 500,
        padding: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: ModelViewer(
              src: 'assets/models/house.glb',
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Color(0xFFF1F5F9)),
        ));
  }

  Widget _buildAnnouncementsCard() {
    return _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ประกาศล่าสุด',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ..._announcements.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.date,
                style: GoogleFonts.outfit(fontSize: 11, color: a.dateColor)),
            Text(a.title,
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ]))),
    ]));
  }

  Widget _buildRepairForm() {
    return _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('แจ้งซ่อมใหม่',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      _textField('หัวข้อปัญหา'),
      const SizedBox(height: 16),
      _textField('รายละเอียด', maxLines: 3),
      const SizedBox(height: 24),
      SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: () {}, child: Text('ส่งคำขอ'))),
    ]));
  }

  Widget _buildRepairStatus() {
    return _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('สถานะปัจจุบัน',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ListTile(
          title: Text('ท่อน้ำอุดตัน'),
          subtitle: Text('กำลังดำเนินการ'),
          trailing: Icon(Icons.timer, color: Colors.orange)),
      ListTile(
          title: Text('หลอดไฟขาด'),
          subtitle: Text('เสร็จสิ้น'),
          trailing: Icon(Icons.check_circle, color: Colors.green)),
    ]));
  }

  Widget _buildFurnitureSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('เฟอร์นิเจอร์และอุปกรณ์',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5),
        itemCount: 6,
        itemBuilder: (context, i) => _card(
            padding: 12,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.kitchen, color: _primary),
              Text('ตู้เย็น',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text('เหลือ 365 วัน',
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.green)),
            ])),
      ),
    ]);
  }

  Widget _card({required Widget child, double padding = 24, double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _border)),
      child: child,
    );
  }

  Widget _buildPageHeader(String title, String sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
      Text(sub, style: GoogleFonts.outfit(fontSize: 14, color: _textMuted)),
    ]);
  }

  Widget _profileRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text('$label: ', style: GoogleFonts.outfit(color: _textMuted)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        ]));
  }

  Widget _settingsToggle(String title, bool val) {
    return SwitchListTile(
        title: Text(title, style: GoogleFonts.outfit(fontSize: 14)),
        value: val,
        onChanged: (_) {},
        activeColor: _primary);
  }

  Widget _settingsDropdown(String label, String val) {
    return ListTile(
        title: Text(label, style: GoogleFonts.outfit(fontSize: 14)),
        trailing:
            Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)));
  }

  Widget _textField(String hint, {int maxLines = 1}) {
    return TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
            hintText: hint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8))));
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}

class _Announcement {
  final String date;
  final Color dateBg;
  final Color dateColor;
  final String title;
  final String desc;
  _Announcement(
      {required this.date,
      required this.dateBg,
      required this.dateColor,
      required this.title,
      required this.desc});
}
