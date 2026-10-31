import 'package:flutter/material.dart';

import 'app_colors.dart';

// Estilos de texto do Figma (Montserrat, declarada no pubspec.yaml).
// Usar com Theme.of(context).textTheme.titleMedium, etc.
// height = altura da linha, em múltiplos do tamanho da letra.
class AppTypography {
  static const TextTheme textTheme = TextTheme(
    // Títulos
    headlineLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: AppColors.gray900,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.25,
      color: AppColors.gray900,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.gray900,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.gray900,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: AppColors.gray900,
    ),

    // Texto corrido
    bodyLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.gray900,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.gray900,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.gray900,
    ),

    // Etiquetas
    labelLarge: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0.1,
      color: AppColors.gray900,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      color: AppColors.gray900,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.33,
      letterSpacing: 0.2,
      color: AppColors.gray900,
    ),
  );
}
