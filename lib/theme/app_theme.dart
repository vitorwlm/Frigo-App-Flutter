import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// os botões do Figma têm cantos de 8 e 48 de altura
final RoundedRectangleBorder _formaBotao = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadius.sm),
);
const Size _tamanhoBotao = Size(64, 48);

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

  // botões: só a forma, a altura e a letra; as cores ficam no AppButton
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: _formaBotao,
      minimumSize: _tamanhoBotao,
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: _formaBotao,
      minimumSize: _tamanhoBotao,
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: _formaBotao,
      minimumSize: _tamanhoBotao,
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary500,
    foregroundColor: AppColors.white,
    extendedTextStyle: AppTypography.textTheme.labelLarge,
    shape: _formaBotao,
  ),

  // barra de baixo como no Figma: fundo cinza claro e pílula teal clara
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.gray100,
    indicatorColor: AppColors.primary200,
    labelTextStyle: WidgetStatePropertyAll(
      AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.gray900),
    ),
  ),

  // Segmento do Figma (Frigorífico / Acabou)
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      selectedBackgroundColor: AppColors.primary600,
      selectedForegroundColor: AppColors.white,
      foregroundColor: AppColors.gray900,
      side: const BorderSide(color: AppColors.gray200),
      textStyle: AppTypography.textTheme.labelLarge,
    ),
  ),
);
