import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryDark = Color(0xFF00796B);
  static const Color secondaryLight = Color(0xFFE0F2F1);
  static const Color accent = Color(0xFFFF6D00);
  static const Color accentLight = Color(0xFFFFF3E0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B7C3);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF1A73E8);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color overlay = Color(0x80000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return warning;
      case 'confirmed': return primary;
      case 'active': return success;
      case 'completed': return textSecondary;
      case 'cancelled': return error;
      case 'in_transit':
      case 'intransit':
      case 'pickedup': return const Color(0xFF8B5CF6);
      case 'delivered': return success;
      default: return textSecondary;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return warningLight;
      case 'confirmed': return primaryLight;
      case 'active': return successLight;
      case 'completed': return divider;
      case 'cancelled': return errorLight;
      case 'in_transit':
      case 'intransit':
      case 'pickedup': return const Color(0xFFEDE9FE);
      case 'delivered': return successLight;
      default: return divider;
    }
  }
}