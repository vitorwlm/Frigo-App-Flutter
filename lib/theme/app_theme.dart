import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// * Tema global, ligado no main.dart. Define aqui o aspeto dos widgets do
// * Material (botões, barra de baixo, cartões…) para os ecrãs não terem de
// * repetir estilos em cada widget.

// ? os botões do Figma têm cantos de 8 e 48 de altura (48 também é o mínimo
// ? recomendado para um dedo acertar no botão)
final RoundedRectangleBorder _formaBotao = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(AppRadius.sm),
);
const Size _tamanhoBotao = Size(64, 48);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  // ? fromSeed gera os tons que eu não defini a partir do teal; os que importam
  // ? ficam fixos na paleta para baterem certo com o Figma
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary500,
    primary: AppColors.primary500,
    onPrimary: AppColors.white,
    error: AppColors.danger500,
    surface: AppColors.white,
  ),
  scaffoldBackgroundColor: AppColors.gray100,
  fontFamily: 'Montserrat',
  // ? apply mete a mesma cor em todos os estilos de texto, em vez de a
  // ? repetir em cada TextStyle do AppTypography
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

  // ? botões: só a forma, a altura e a letra; as cores ficam no AppButton,
  // ? porque há variantes (principal, perigo, tonal) com cores diferentes
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

  // ? barra de baixo como no Figma: fundo cinza claro e pílula teal clara
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.gray100,
    indicatorColor: AppColors.primary200,
    labelTextStyle: WidgetStatePropertyAll(
      AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.gray900),
    ),
  ),

  // ? Segmento do Figma (Frigorífico / Acabou, no Inventário)
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
