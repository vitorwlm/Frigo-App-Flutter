import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'app_colors.dart';

// Tema da app inteira: mudar aqui muda em todos os ecrãs.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  // fromSeed gera os tons; primary, error e surface ficam iguais à paleta
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary500,
    primary: AppColors.primary500,
    onPrimary: AppColors.white,
    error: AppColors.danger500,
    surface: AppColors.white,
  ),
  scaffoldBackgroundColor: AppColors.gray100,
  textTheme: AppTypography.textTheme,
  // estilo de todas as AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary500,
    foregroundColor: AppColors.primary100,
    titleTextStyle: TextStyle(
      fontFamily: 'Montserrat',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primary100,
    ),
  ),
  // estilo de todos os Card
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 0, // sem sombra
    margin: EdgeInsets.zero, // o espaço vem do Padding do ecrã
    // cantos arredondados + contorno cinzento
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.gray200),
    ),
  ),
);
