import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/features/legal/presentation/screens/legal_dashboard/widgets/shared/dashboard_theme.dart';
import 'package:fcm_app/core/services/translation_service.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const SettingsView({super.key, this.onMenuTap});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _pushNotifications = true;
  final _ts = TranslationService.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DashboardTheme.isDarkMode,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<String>(
          valueListenable: _ts.currentLanguage,
          builder: (context, lang, _) {
            return Stack(
              children: [
                Container(
                  color: DashboardTheme.background,
                  padding: const EdgeInsets.fromLTRB(40, 72, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.onMenuTap != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: widget.onMenuTap,
                                child: Icon(Icons.menu_rounded,
                                    color: DashboardTheme.primary, size: 28),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _ts.t('settings_title'),
                                  style: GoogleFonts.outfit(
                                    color: DashboardTheme.textMain,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _ts.t('settings_subtitle'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: DashboardTheme.textPale,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      _settingsRow(
                        _ts.t('dark_mode'),
                        _ts.t('dark_mode_desc'),
                        isDark,
                        onChanged: (v) => DashboardTheme.isDarkMode.value = v,
                      ),
                      _settingsRow(
                        _ts.t('push_notifications'),
                        _ts.t('push_notifications_desc'),
                        _pushNotifications,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                      ),
                      _languageRow(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _languageRow() {
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
                  _ts.t('language'),
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ts.t('language_desc'),
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _ts.lang,
            dropdownColor: DashboardTheme.surface,
            underline: const SizedBox(),
            style: GoogleFonts.notoSans(
              color: DashboardTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(Icons.arrow_drop_down, color: DashboardTheme.primary),
            items: TranslationService.availableLanguages.map((l) {
              return DropdownMenuItem<String>(
                value: l['code'],
                child: Text(l['label']!,
                    style: GoogleFonts.notoSans(
                      color: DashboardTheme.textMain,
                      fontSize: 14,
                    )),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _ts.setLanguage(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(String title, String subtitle, bool? value,
      {ValueChanged<bool>? onChanged}) {
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
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSans(
                    color: DashboardTheme.textPale,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (value != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: DashboardTheme.primary,
              activeTrackColor: DashboardTheme.primary.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}
