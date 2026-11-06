import 'package:flutter/material.dart';

// height = altura da linha (x tamanho da letra)
class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // Números grandes dos cartões hero (Display/Large no Figma)
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      height: 1.0,
      letterSpacing: -1,
    ),

    // Títulos
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),

    // Texto corrido
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    ),

    // Etiquetas
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.2,
    ),
  );
}
