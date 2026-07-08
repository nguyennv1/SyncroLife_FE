import 'package:flutter/material.dart';

class AppColors {
  static bool isDark = true;

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color lightPrimary = Color(0xFF60A5FA);
  static const Color accentTeal = Color(0xFF10B981);
  static const Color overlapRed = Color(0xFFEF4444);
  static const Color darkYellow = Color(0xFFEAB308);

  static Color get backgroundDark => isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9);
  static Color get cardDark => isDark ? const Color(0xFF131B2D) : const Color(0xFFFFFFFF);
  static Color get textLight => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textMuted => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color get border => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get inputFill => isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  static Color get inputBorder => isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
  static Color get googleBg => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
  static Color get googleBorder => isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
}
