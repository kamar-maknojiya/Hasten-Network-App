import 'package:flutter/material.dart';

class AppColors {

  static const Color primary = Color(0xFFD81B60);
  static const Color secondary = Color(0xFF0B72D9);
  static const Color navy = Color(0xFF122C55);

  static const Color orange = Color(0xFFF5A623);
  static const Color gold = orange;
  static const Color red = Color(0xFFDC2626);
  static const Color green = Color(0xFF16A34A);
  static const Color teal = Color(0xFF0D9488);

  // DARK
  static const darkBg = Color(0xff0A101C);
  static const darkCard = Color(0xff131929);
  static const darkCard1 = Color(0xff141929);
  static const darkCard2 = Color(0xff1A2030);
  // LIGHT
  static const lightBg = Color(0xffF3F4F8);
  static const lightCard = Color(0xffffffff);
  static const lightCard1 = Color(0xffE3EBF8);
  static const lightCard2 = Color(0xffF5F6F6);

  static const textDark = Colors.white;
  static const textLight = Color(0xff1A1A1A);

  /// Lighter pink → deeper pink. Used for CTAs/buttons and any primary-brand fill.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF0407F), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = primaryGradient;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, gold],
  );

  static const LinearGradient statusCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B0F3C), primary],
  );

  static const SweepGradient usageRingGradient = SweepGradient(
    colors: [Color(0xFFF0407F), primary, Color(0xFFF0407F)],
  );
}

