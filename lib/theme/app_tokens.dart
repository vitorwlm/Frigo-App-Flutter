import 'package:flutter/material.dart';

import 'app_colors.dart';

// Cores com significado (coleção "tokens" do Figma).
// Os ecrãs usam estas; a paleta (AppColors) só se usa aqui.
class AppTokens {
  // fundos
  static const Color bgApp = AppColors.gray100;
  static const Color bgSurface = AppColors.white;
  static const Color bgSubtle = AppColors.gray100;
  static const Color bgTrack = AppColors.gray200;
  static const Color bgTonal = AppColors.primary200;
  static const Color bgTonalSoft = AppColors.primary100;
  static const Color bgDanger = AppColors.danger100;
  static const Color bgWarning = AppColors.warning100;

  // cartões hero (o grande cartão de cima)
  static const Color heroOk = AppColors.primary600;
  static const Color heroDanger = AppColors.danger600;
  static const Color heroWarning = AppColors.warning700;
  static const Color heroOffline = AppColors.gray600;
  static const Color heroOverlay = AppColors.white16;
  static const Color heroBorder = AppColors.white24;

  // texto
  static const Color textPrimary = AppColors.gray900;
  static const Color textSecondary = AppColors.gray500;
  static const Color textOnHero = AppColors.white;
  static const Color textBrand = AppColors.primary700;
  static const Color textDanger = AppColors.danger600;
  static const Color textWarning = AppColors.warning700;

  // contornos
  static const Color border = AppColors.gray200;
  static const Color borderStrong = AppColors.gray400;

  // barra de cor das linhas
  static const Color statusDanger = AppColors.danger500;
  static const Color statusWarning = AppColors.warning500;
  static const Color statusNeutral = AppColors.gray400;
  static const Color statusBrand = AppColors.primary500;
}
