import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  // fromSeed gera os tons a partir de uma cor; os outros ficam fixos na paleta
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary500,
    primary: AppColors.primary500,
    onPrimary: AppColors.white,
    error: AppColors.danger500,
    surface: AppColors.white,
  ),
  scaffoldBackgroundColor: AppColors.gray100,
  fontFamily: 'Montserrat',
  // apply mete a mesma cor em todos os estilos de texto
  textTheme: AppTypography.textTheme.apply(
    bodyColor: AppColors.gray900,
    displayColor: AppColors.gray900,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary500,
    foregroundColor: AppColors.primary100,
  ),
  cardTheme: CardThemeData(
    color: AppColors.white,
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
);
