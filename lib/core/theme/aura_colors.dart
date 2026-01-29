import 'package:flutter/material.dart';

/// A.U.R.A. design system colors — matches aura-smart-home-agent (Lovable) reference.
/// Slate Blue #0F2540, AURA Teal #00C2B8, Coral Orange #FF6A5C, Cloud White #F8FAFC.
class AuraColors {
  AuraColors._();

  // Primary accents (from reference index.css)
  static const Color teal = Color(0xFF00C2B8);       // AURA Teal 175 100% 38%
  static const Color tealLight = Color(0xFF4DD4CC);
  static const Color tealDark = Color(0xFF00A399);   // primary-dark
  static const Color coral = Color(0xFFFF6A5C);     // Coral Orange 6 100% 68%
  static const Color coralDark = Color(0xFFE85A4C);

  // Backgrounds
  static const Color darkSlate = Color(0xFF0F2540);   // Slate Blue 210 62% 15%
  static const Color darkSlateBg = Color(0xFF132D4D);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color lightGreyCard = Color(0xFFE8E8E8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D3E50);
  static const Color cloudWhite = Color(0xFFF8FAFC);  // reference Cloud White

  // Text
  static const Color textDark = Color(0xFF0F2540);   // foreground = slate
  static const Color textLight = Color(0xFF64748B);   // Neutral Gray reference
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnTeal = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successCheck = Color(0xFF22C55E);
}
