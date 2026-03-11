import 'package:flutter/material.dart';

/// Vivorn Villa — Multi-language Translation Service
/// Supports: English (en), Thai (th), Chinese (zh)

class TranslationService {
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  /// Current language notifier — UI rebuilds when changed
  final ValueNotifier<String> currentLanguage = ValueNotifier('en');

  /// Shorthand
  String get lang => currentLanguage.value;

  /// Translate a key
  String t(String key) {
    return _translations[lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  /// Change language
  void setLanguage(String langCode) {
    if (_translations.containsKey(langCode)) {
      currentLanguage.value = langCode;
    }
  }

  /// All available languages
  static const List<Map<String, String>> availableLanguages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'th', 'label': 'ไทย'},
    {'code': 'zh', 'label': '中文'},
  ];

  // ════════════════════════════════════════════════════════════
  // Translation Map
  // ════════════════════════════════════════════════════════════
  static const Map<String, Map<String, String>> _translations = {
    // ── English ──
    'en': {
      // Brand
      'brand_title': 'VIVORN VILLA',
      'brand_subtitle_resident': 'RESIDENT PORTAL',
      'brand_subtitle_admin': 'MANAGEMENT PORTAL',
      'brand_subtitle_tech': 'TECHNICIAN PORTAL',

      // Sidebar
      'nav_dashboard': 'DASHBOARD',
      'nav_history': 'REQUEST HISTORY',
      'nav_profile': 'PROFILE',
      'nav_settings': 'SETTINGS',

      // Dashboard / Home
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'status_all_normal': 'All Systems Normal',
      'news_label': 'NEWS',

      // AI Chat
      'ai_chat_fab': 'Chat with AI',
      'v_chat_with_ai': 'V Chat with AI',

      // AI Chat Panel UI
      'ai_panel_title': 'Vivorn AI Assistant',
      'ai_panel_search': 'Search...',
      'ai_panel_no_chats': 'No previous chats',
      'ai_panel_assistant_name': 'System AI Assistant',
      'ai_panel_typing': 'Typing...',
      'ai_panel_online': 'Online',
      'ai_panel_input_hint': 'Tell me what you need fixed...',
      'ai_panel_delete_title': 'Delete Chat',
      'ai_panel_delete_body':
          'Are you sure you want to delete this conversation?',
      'ai_panel_delete_confirm': 'Delete',
      'ai_panel_new_chat': 'New Chat',

      // Request Preview Card
      'request_preview_title': 'MAINTENANCE REQUEST PREVIEW',
      'request_preview_tasks': 'task(s)',
      'request_preview_confirm': 'Confirm Request',
      'request_preview_cancel': 'Cancel',
      'request_preview_emergency': 'EMERGENCY',
      'request_preview_submitted': 'Request submitted!',

      // History
      'history_title': 'Request History',
      'history_subtitle':
          'Track and manage your property maintenance records with precision.',
      'filter_all': 'All',
      'filter_pending': 'Pending',
      'filter_active': 'Active',
      'filter_completed': 'Completed',
      'empty_records': 'No records found in this registry',
      'service_report': 'Service Report',
      'chronology': 'Chronology',
      'logged_on': 'Logged On',
      'schedule': 'Schedule',
      'completed_label': 'Completed',
      'assigned_technician': 'ASSIGNED TECHNICIAN',
      'photo_documentation': 'Photo Documentation',
      'cancel_request': 'Cancel Request',
      'cancel_confirm_title': 'Cancel Request?',
      'cancel_confirm_body':
          'Are you sure you want to retract this repair request? This action cannot be undone.',
      'go_back': 'GO BACK',
      'confirm_cancel': 'CONFIRM CANCEL',
      'request_cancelled': 'Request cancelled successfully',
      'feedback_submitted': 'Feedback submitted successfully!',
      'assess': 'Assess',
      'cancel': 'Cancel',

      // Feedback Card
      'feedback_header': 'SERVICE COMPLETION',
      'feedback_title': 'FEEDBACK CARD',
      'task_id': 'TASK ID',
      'service': 'SERVICE',
      'date': 'DATE',
      'technician': 'TECHNICIAN',
      'quality_assessment': 'QUALITY ASSESSMENT',
      'additional_notes': 'ADDITIONAL NOTES',
      'notes_hint': 'Share your experience...',
      'submit_feedback': 'SUBMIT FEEDBACK',

      // Profile
      'profile_account': 'Account',
      'profile_subtitle':
          'Manage your personal profile and account credentials.',
      'profile_name': 'Name',
      'profile_email': 'Email',
      'profile_phone': 'Phone',
      'profile_position': 'Position',
      'profile_position_hint': 'e.g. Electrician, Plumber',
      'change_password': 'Change password',
      'edit_dialog_title': 'Edit',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'password_mismatch': 'Passwords do not match',
      'password_too_short': 'Password must be at least 8 characters',
      'save_changes': 'SAVE CHANGES',
      'cancel_action': 'CANCEL',
      'updated_success': 'updated successfully',

      // Settings
      'settings_header': 'MANAGEMENT // SYSTEM CONFIGURATION',
      'settings_title': 'Settings',
      'settings_subtitle':
          'Configure your system preferences and application interface.',
      'dark_mode': 'DARK MODE',
      'dark_mode_desc': 'Dark Mode (System Sync)',
      'push_notifications': 'PUSH NOTIFICATIONS',
      'push_notifications_desc': 'Push Notifications for all activities',
      'language': 'LANGUAGE',
      'language_desc': 'Display language',

      // Logout
      'logout_title': 'Logout',
      'logout_body': 'Do you want to logout?',
      'logout_cancel': 'CANCEL',
      'logout_confirm': 'LOGOUT',
    },

    // ── Thai ──
    'th': {
      'brand_title': 'วิวร วิลล่า',
      'brand_subtitle_resident': 'พอร์ทัลผู้พักอาศัย',
      'brand_subtitle_admin': 'พอร์ทัลผู้จัดการ',
      'brand_subtitle_tech': 'พอร์ทัลช่าง',
      'nav_dashboard': 'หน้าหลัก',
      'nav_history': 'ประวัติคำร้อง',
      'nav_profile': 'โปรไฟล์',
      'nav_settings': 'ตั้งค่า',
      'greeting_morning': 'สวัสดีตอนเช้า',
      'greeting_afternoon': 'สวัสดีตอนบ่าย',
      'greeting_evening': 'สวัสดีตอนเย็น',
      'status_all_normal': 'ระบบทั้งหมดปกติ',
      'news_label': 'ข่าวสาร',
      'ai_chat_fab': 'แชทกับ AI',
      'v_chat_with_ai': 'V คุยกับ AI',

      // AI Chat Panel UI
      'ai_panel_title': 'Vivorn AI Assistant',
      'ai_panel_search': 'ค้นหา...',
      'ai_panel_no_chats': 'ไม่มีประวัติการสนทนา',
      'ai_panel_assistant_name': 'AI ระบบวิวอร์น',
      'ai_panel_typing': 'กำลังพิมพ์...',
      'ai_panel_online': 'ออนไลน์',
      'ai_panel_input_hint': 'บอกความต้องการของคุณ...',
      'ai_panel_delete_title': 'ลบการสนทนา',
      'ai_panel_delete_body': 'คุณแน่ใจหรือไม่ว่าต้องการลบการสนทนานี้?',
      'ai_panel_delete_confirm': 'ลบ',
      'ai_panel_new_chat': 'สนทนาใหม่',

      // Request Preview Card
      'request_preview_title': 'ตรวจสอบคำร้องซ่อม',
      'request_preview_tasks': 'รายการ',
      'request_preview_confirm': 'ยืนยันคำร้อง',
      'request_preview_cancel': 'ยกเลิก',
      'request_preview_emergency': 'ฉุกเฉิน',
      'request_preview_submitted': 'ส่งคำร้องเรียบร้อย!',
      'history_title': 'ประวัติคำร้อง',
      'history_subtitle':
          'ติดตามและจัดการบันทึกการบำรุงรักษาทรัพย์สินของคุณอย่างแม่นยำ',
      'filter_all': 'ทั้งหมด',
      'filter_pending': 'รอดำเนินการ',
      'filter_active': 'กำลังดำเนินการ',
      'filter_completed': 'เสร็จสิ้น',
      'empty_records': 'ไม่พบข้อมูลในรายการนี้',
      'service_report': 'รายงานการซ่อม',
      'chronology': 'ลำดับเวลา',
      'logged_on': 'วันที่แจ้ง',
      'schedule': 'นัดหมาย',
      'completed_label': 'เสร็จสิ้น',
      'assigned_technician': 'ช่างที่ได้รับมอบหมาย',
      'photo_documentation': 'เอกสารภาพถ่าย',
      'cancel_request': 'ยกเลิกคำขอ',
      'cancel_confirm_title': 'ยกเลิกคำขอ?',
      'cancel_confirm_body':
          'คุณแน่ใจหรือไม่ว่าต้องการเพิกถอนคำขอซ่อม? การดำเนินการนี้ไม่สามารถย้อนกลับได้',
      'go_back': 'ย้อนกลับ',
      'confirm_cancel': 'ยืนยันยกเลิก',
      'request_cancelled': 'ยกเลิกคำขอสำเร็จ',
      'feedback_submitted': 'ส่งความคิดเห็นสำเร็จ!',
      'assess': 'ประเมิน',
      'cancel': 'ยกเลิก',
      'feedback_header': 'การซ่อมเสร็จสิ้น',
      'feedback_title': 'บัตรประเมินผล',
      'task_id': 'รหัสงาน',
      'service': 'บริการ',
      'date': 'วันที่',
      'technician': 'ช่าง',
      'quality_assessment': 'การประเมินคุณภาพ',
      'additional_notes': 'หมายเหตุเพิ่มเติม',
      'notes_hint': 'แบ่งปันประสบการณ์ของคุณ...',
      'submit_feedback': 'ส่งความคิดเห็น',
      'profile_account': 'บัญชี',
      'profile_subtitle': 'จัดการข้อมูลส่วนตัวและรหัสผ่านเข้าสู่ระบบของคุณ',
      'profile_name': 'ชื่อ',
      'profile_email': 'อีเมล',
      'profile_phone': 'โทรศัพท์',
      'profile_position': 'ตำแหน่ง',
      'profile_position_hint': 'เช่น ช่างไฟฟ้า, ช่างประปา',
      'change_password': 'เปลี่ยนรหัสผ่าน',
      'edit_dialog_title': 'แก้ไข',
      'new_password': 'รหัสผ่านใหม่',
      'confirm_password': 'ยืนยันรหัสผ่าน',
      'password_mismatch': 'รหัสผ่านไม่ตรงกัน',
      'password_too_short': 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
      'save_changes': 'บันทึกการเปลี่ยนแปลง',
      'cancel_action': 'ยกเลิก',
      'updated_success': 'อัปเดตสำเร็จ',
      'settings_header': 'การจัดการ // การตั้งค่าระบบ',
      'settings_title': 'การตั้งค่าระบบ',
      'settings_subtitle':
          'กำหนดค่าความต้องการของท่านและรูปแบบส่วนติดต่อผู้ใช้งาน',
      'dark_mode': 'โหมดมืด',
      'dark_mode_desc': 'โหมดมืด (ซิงค์กับระบบ)',
      'push_notifications': 'การแจ้งเตือน',
      'push_notifications_desc': 'การแจ้งเตือนสำหรับทุกกิจกรรม',
      'language': 'ภาษา',
      'language_desc': 'ภาษาที่แสดงผล',
      'logout_title': 'ออกจากระบบ',
      'logout_body': 'คุณต้องการออกจากระบบหรือไม่?',
      'logout_cancel': 'ยกเลิก',
      'logout_confirm': 'ออกจากระบบ',
    },

    // ── Chinese ──
    'zh': {
      'brand_title': 'VIVORN别墅',
      'brand_subtitle_resident': '住户门户',
      'brand_subtitle_admin': '管理门户',
      'brand_subtitle_tech': '技术人员门户',
      'nav_dashboard': '仪表板',
      'nav_history': '申请记录',
      'nav_profile': '个人资料',
      'nav_settings': '设置',
      'greeting_morning': '早上好',
      'greeting_afternoon': '下午好',
      'greeting_evening': '晚上好',
      'status_all_normal': '所有系统正常',
      'news_label': '新闻',
      'ai_chat_fab': '与AI聊天',
      'v_chat_with_ai': 'V 与 AI 聊天',

      // AI Chat Panel UI
      'ai_panel_title': 'Vivorn AI助手',
      'ai_panel_search': '搜索...',
      'ai_panel_no_chats': '暂无聊天记录',
      'ai_panel_assistant_name': 'Vivorn系统AI',
      'ai_panel_typing': '正在输入...',
      'ai_panel_online': '在线',
      'ai_panel_input_hint': '请告诉我您需要什么帮助...',
      'ai_panel_delete_title': '删除聊天',
      'ai_panel_delete_body': '您确定要删除此对话吗？',
      'ai_panel_delete_confirm': '删除',
      'ai_panel_new_chat': '新对话',

      // Request Preview Card
      'request_preview_title': '维修请求预览',
      'request_preview_tasks': '项任务',
      'request_preview_confirm': '确认请求',
      'request_preview_cancel': '取消',
      'request_preview_emergency': '紧急',
      'request_preview_submitted': '请求已提交！',
      'history_title': '申请记录',
      'history_subtitle': '精确追踪和管理您的物业维护记录。',
      'filter_all': '全部',
      'filter_pending': '待处理',
      'filter_active': '进行中',
      'filter_completed': '已完成',
      'empty_records': '此注册表中未找到记录',
      'service_report': '维修报告',
      'chronology': '时间线',
      'logged_on': '登记日期',
      'schedule': '预约',
      'completed_label': '已完成',
      'assigned_technician': '指定技术人员',
      'photo_documentation': '照片文档',
      'cancel_request': '取消请求',
      'cancel_confirm_title': '取消请求？',
      'cancel_confirm_body': '您确定要撤回此维修请求吗？此操作不可撤销。',
      'go_back': '返回',
      'confirm_cancel': '确认取消',
      'request_cancelled': '请求已成功取消',
      'feedback_submitted': '反馈提交成功！',
      'assess': '评估',
      'cancel': '取消',
      'feedback_header': '服务完成',
      'feedback_title': '反馈卡',
      'task_id': '任务编号',
      'service': '服务',
      'date': '日期',
      'technician': '技术人员',
      'quality_assessment': '质量评估',
      'additional_notes': '附加说明',
      'notes_hint': '分享您的体验...',
      'submit_feedback': '提交反馈',
      'profile_account': '账户',
      'profile_subtitle': '管理您的个人资料和账户凭据。',
      'profile_name': '姓名',
      'profile_email': '邮箱',
      'profile_phone': '电话',
      'change_password': '更改密码',
      'edit_dialog_title': '编辑',
      'new_password': '新密码',
      'confirm_password': '确认密码',
      'password_mismatch': '密码不匹配',
      'password_too_short': '密码至少需要8个字符',
      'save_changes': '保存更改',
      'cancel_action': '取消',
      'updated_success': '更新成功',
      'settings_header': '管理 // 系统配置',
      'settings_title': '系统设置',
      'settings_subtitle': '配置系统偏好设置和应用程序界面。',
      'dark_mode': '深色模式',
      'dark_mode_desc': '深色模式（系统同步）',
      'push_notifications': '推送通知',
      'push_notifications_desc': '所有活动的推送通知',
      'language': '语言',
      'language_desc': '显示语言',
      'logout_title': '退出登录',
      'logout_body': '您要退出登录吗？',
      'logout_cancel': '取消',
      'logout_confirm': '退出登录',
    },
  };
}
