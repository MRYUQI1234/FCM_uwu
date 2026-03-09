import 'package:flutter/material.dart';

class DashboardTheme {
  // Global Theme State: Default to DARK MODE as requested
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

  // --- DARK MODE PALETTE ---
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF151515);
  static const Color surfaceSecondaryDark = Color(0xFF1A1A1A);
  static const Color textMainDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;
  static const Color textPaleDark = Colors.white38;
  static const Color borderDark = Color(0xFF222222);
  static const Color borderSubtleDark = Color(0xFF1A1A1A);

  // --- LIGHT MODE PALETTE ---
  static const Color backgroundLight = Color(0xFFFDFBF7);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceSecondaryLight = Color(0xFFF8F4ED);
  static const Color textMainLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textPaleLight = Color(0xFFAAAAAA);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderSubtleLight = Color(0xFFF5F5F5);

  // --- DYNAMIC GETTERS ---
  static Color get background => isDarkMode.value ? backgroundDark : backgroundLight;
  static Color get surface => isDarkMode.value ? surfaceDark : surfaceLight;
  static Color get surfaceSecondary => isDarkMode.value ? surfaceSecondaryDark : surfaceSecondaryLight;
  
  static Color get textMain => isDarkMode.value ? textMainDark : textMainLight;
  static Color get textSecondary => isDarkMode.value ? textSecondaryDark : textSecondaryLight;
  static Color get textPale => isDarkMode.value ? textPaleDark : textPaleLight;
  
  static Color get border => isDarkMode.value ? borderDark : borderLight;
  static Color get borderSubtle => isDarkMode.value ? borderSubtleDark : borderSubtleLight;

  // --- FIXED ACCENTS ---
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color accentAmber = Color(0xFFC5A059);
  static const Color success = Color(0xFF00A36C);
  static const Color warning = Color(0xFFFF9900);
  static const Color error = Color(0xFFFF3333);

  // --- DYNAMIC ACCENTS ---
  // "Primary" changes based on mode: Gold for Dark, Blue for Light
  static Color get primary => isDarkMode.value ? accentAmber : primaryBlue;
  
  static Color get primaryDim => isDarkMode.value ? accentAmberDim : primaryBlueDim;
  static Color get primaryBlueDim => isDarkMode.value ? primaryBlue.withOpacity(0.1) : const Color(0xFFE6F0FF);
  static Color get accentAmberDim => isDarkMode.value ? accentAmber.withOpacity(0.1) : const Color(0xFFFAF3E6);

  // --- DECORATIONS ---
  static BoxDecoration cardDecoration({Color? color, Color? borderColor, double borderRadius = 28}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? border,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode.value ? 0.2 : 0.03),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }
}
