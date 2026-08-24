import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Enterprise Palette (Deep Slate & Indigo)
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Indigo
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primarySurface = Color(0xFFEEF2FF); // Soft Indigo surface

  // Secondary & Accents
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentLight = Color(0xFFE0F2FE);

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Sidebar Specific Palette (Deep Slate Enterprise)
  static const Color sidebarBg = Color(0xFF0F172A); // Slate 900
  static const Color sidebarHover = Color(0xFF1E293B); // Slate 800
  static const Color sidebarActive = Color(0xFF1E3A8A); // Indigo active
  static const Color sidebarText = Color(0xFF94A3B8); // Slate 400
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status & Badges
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF047857);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Domain Specific Colors
  static const Color utilityAmber = Color(0xFFD97706); // Electricity / Gas
  static const Color utilityAmberLight = Color(0xFFFEF3C7);
  static const Color warrantyEmerald = Color(0xFF059669); // Warranty Active
  static const Color warrantyEmeraldLight = Color(0xFFD1FAE5);
  static const Color taxPurple = Color(0xFF7C3AED); // Legal / Tax
  static const Color financeBlue = Color(0xFF2563EB); // Banking / Invoices
  static const Color starFilled = Color(0xFFFFB020); // Gold Star
}
