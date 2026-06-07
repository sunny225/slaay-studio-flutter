import 'package:flutter/material.dart';

class AppColors {
  // --- CHOOSE ACTIVE THEME ---
  // Set to true to test the new Premium theme, false to revert to the original Void Black theme
  static const bool usePremiumTheme = false;

  // Primary brand / button color
  static const Color primary = usePremiumTheme ? Color(0xFF907090) : Color(0xFF0A0A0A);
  static const Color primaryDark = usePremiumTheme ? Color(0xFFA080A0) : Color(0xFF0A0A0A);
  
  // Accent color (buttons, highlights, focus borders)
  static const Color accent = usePremiumTheme ? Color(0xFFD4AF37) : Color(0xFF1A1A1A);
  static const Color accentDark = usePremiumTheme ? Color(0xFFE8D8A8) : Color(0xFF1A1A1A);
  
  // Secondary color (muted captions, borders)
  static const Color secondary = usePremiumTheme ? Color(0xFF807090) : Color(0xFF888888);
  
  // Backgrounds
  static const Color backgroundLight = usePremiumTheme ? Color(0xFFF8F5F7) : Color(0xFFFFFFFF);
  static const Color backgroundDark = usePremiumTheme ? Color(0xFF2B2330) : Color(0xFF0A0A0A);
  
  // Premium linear base gradients synced to user color codes
  static const Gradient premiumBgGradientLight = LinearGradient(
    colors: [Color(0xFFF8F5F7), Color(0xFFF3EEF1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const Gradient premiumBgGradientDark = LinearGradient(
    colors: [Color(0xFF2B2330), Color(0xFF241C29)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dynamic Scaffold Background Color Selector
  static Color scaffoldBgColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? backgroundDark : backgroundLight;
  }

  // Surfaces & Cards
  static const Color surfaceLight = usePremiumTheme ? Color(0xFFFFFFFF) : Color(0xFFFFFFFF);
  static const Color surfaceDark = usePremiumTheme ? Color(0xFF3A2F3D) : Color(0xFF1A1A1A);
  
  // Text Colors
  static const Color textPrimaryLight = usePremiumTheme ? Color(0xFF3A2F3D) : Color(0xFF0A0A0A);
  static const Color textSecondaryLight = usePremiumTheme ? Color(0xFF6B5A6E) : Color(0xFF888888);
  static const Color textPrimaryDark = usePremiumTheme ? Color(0xFFF8F5F7) : Color(0xFFFFFFFF);
  static const Color textSecondaryDark = usePremiumTheme ? Color(0xFFC0A0B0) : Color(0xFF888888);
  
  // Feedback Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);
  
  // Borders & Dividers
  static const Color borderLight = usePremiumTheme ? Color(0xFFE0D0D0) : Color(0xFFCCCCCC);
  static const Color borderDark = usePremiumTheme ? Color(0xFFD0C0C0) : Color(0xFF1A1A1A);

  // Gradients synced to Style Guide
  static const Gradient burgundyGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFF888888), Color(0xFFCCCCCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium Neon Accent Tones
  static const Color neonAmethyst = Color(0xFF9B5DE5);
  static const Color neonPink = Color(0xFFF15BB5);
  static const Color neonYellow = Color(0xFFFEE440);
  static const Color neonBlue = Color(0xFF00F5D4);
  static const Color electricIndigo = Color(0xFF6C5CE7);
  static const Color roseGold = Color(0xFFE0A96D);

  // Organic Blends for Liquid Glass backgrounds
  static const Gradient liquidPurpleGradient = LinearGradient(
    colors: [Color(0xFF9B5DE5), Color(0xFFF15BB5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient liquidCyanGradient = LinearGradient(
    colors: [Color(0xFF00F5D4), Color(0xFF00BBF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient liquidSunsetGradient = LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFFFF7F50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
