import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFB71C1C); // Vibrant Red from logo/packaging
  static const Color primaryGold = Color(0xFFFFD700); // Gold from buttons/logo
  static const Color primaryGreen = Color(0xFF2E7D32); // Fresh Tea Green
  static const Color secondaryGold = Color(0xFFE6B940); // Muted Gold
  
  static const Color primaryOrange = Color(0xFFFF5722); // Vibrant Red-Yellow mix (Deep Orange)
  static const Color primaryOrangeLight = Color(0xFFFF8A65); // Lighter Orange for gradient
  static const Color primaryOrangeDark = Color(0xFFE64A19); // Darker Orange for gradient

  // Website Brand Colors
  static const Color websiteGradientStart = Color(0xFFED1B24); // Brand Red from website
  static const Color websiteGradientEnd = Color(0xFFFFB100);   // Brand Yellow-Orange from website

  static BoxDecoration get websiteBackground => const BoxDecoration(
    color: Colors.white,
  );
  
  static const Color backgroundLight = Colors.white; // Pure white background as requested
  static const Color backgroundDark = Color(0xFF121212);
  
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF757575);
  
  static const Color cardGrey = Color(0xFFEEEEEE); // Slightly darker for contrast
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

