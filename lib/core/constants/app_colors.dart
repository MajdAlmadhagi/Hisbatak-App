import 'package:flutter/material.dart';

/// [AppColors] defines the curated color palette extracted directly from
/// the Stitch "Offline Arabic Fintech UI" design system.
///
/// SOLID Principle: Single Responsibility Principle (SRP)
/// Responsible solely for defining centralized theme colors and token constants.
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF0F172A); // Dark slate navy
  static const Color primaryDark = Color(0xFF0B1120);
  static const Color primaryLight = Color(0xFF1E293B);

  // Emerald & Mint Accents (Fintech Green / Success / Active)
  static const Color emerald = Color(0xFF006C49);
  static const Color emeraldLight = Color(0xFF00A86B);
  static const Color mintContainer = Color(0xFF6CF8BB);
  static const Color mintSoft = Color(0xFFE6FBF2);
  static const Color mintFixed = Color(0xFF6FFBBE);

  // Status & Financial Indicators
  static const Color income = Color(0xFF00875A); // Positive green
  static const Color expense = Color(0xFFEF4444); // Negative red
  static const Color expenseSoft = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  // Background & Surfaces
  static const Color background = Color(0xFFF7F9FB); // Clean soft gray background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECEEF0);
  static const Color surfaceVariantDark = Color(0xFF1E293B);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color cardDark = Color(0xFF131B2E);
  static const Color cardDarkElevated = Color(0xFF1E293B);

  // Text & Content
  static const Color textPrimary = Color(0xFF191C1E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderVariant = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF334155);
  static const Color outline = Color(0xFF76777D);

  // Category Colors
  static const Color catRestaurants = Color(0xFFEF4444); // Red/Orange
  static const Color catGroceries = Color(0xFF10B981); // Emerald
  static const Color catBills = Color(0xFF1E293B); // Dark Slate
  static const Color catEntertainment = Color(0xFF6366F1); // Indigo
  static const Color catTransport = Color(0xFFF59E0B); // Amber
}
