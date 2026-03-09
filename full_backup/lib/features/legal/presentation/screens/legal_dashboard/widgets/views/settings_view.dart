import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _pushNotifications = true;
  bool _autoAssign = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return Container(
          color: DashboardTheme.background,
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MANAGEMENT // SYSTEM CONFIGURATION",
                style: GoogleFonts.notoSans(
                  color: DashboardTheme.primary, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "System Configuration",
                style: GoogleFonts.notoSans(
                  color: DashboardTheme.textMain, 
                  fontSize: 32, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 48),
              _settingsRow(
                "DARK MODE", 
                "Dark Mode (System Sync)", 
                isDark,
                onChanged: (v) => DashboardTheme.isDarkMode.value = v,
              ),
              _settingsRow(
                "PUSH NOTIFICATIONS", 
                "Push Notifications for all activities", 
                _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              _settingsRow(
                "AUTO-ASSIGN", 
                "Auto-assign tasks when technicians are available", 
                _autoAssign,
                onChanged: (v) => setState(() => _autoAssign = v),
              ),
              _settingsRow("LANGUAGE", "English (US)", null),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsRow(String title, String subtitle, bool? value, {ValueChanged<bool>? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textMain, 
                    fontWeight: FontWeight.w700, 
                    fontSize: 14,
                    letterSpacing: 0.5
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale, 
                    fontSize: 12
                  )
                ),
              ],
            ),
          ),
          if (value != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: DashboardTheme.primary,
              activeTrackColor: DashboardTheme.primary.withOpacity(0.2),
            ),
          if (value == null)
            Icon(Icons.arrow_forward_ios, color: DashboardTheme.textPale, size: 14),
        ],
      ),
    );
  }
}
