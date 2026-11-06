import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

// enum = lista fechada de opções (como as variantes "tom" do Figma)
enum TagTom { perigo, aviso, neutro, marca, contorno, contornoHero }

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.texto, this.tom = TagTom.neutro});

  final String texto;
  final TagTom tom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color? fundo;
    Color corTexto;
    Color? borda;
    switch (tom) {
      case TagTom.perigo:
        fundo = AppTokens.bgDanger;
        corTexto = AppTokens.textDanger;
      case TagTom.aviso:
        fundo = AppTokens.bgWarning;
        corTexto = AppTokens.textWarning;
      case TagTom.neutro:
        fundo = AppTokens.bgSubtle;
        corTexto = AppColors.gray700;
        borda = AppTokens.border;
      case TagTom.marca:
        fundo = AppTokens.bgTonalSoft;
        corTexto = AppTokens.textBrand;
      case TagTom.contorno:
        corTexto = AppTokens.textSecondary;
        borda = AppTokens.borderStrong;
      case TagTom.contornoHero:
        corTexto = AppTokens.textOnHero;
        borda = AppTokens.heroBorder;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: borda == null ? null : Border.all(color: borda),
      ),
      child: Text(
        texto,
        style: textTheme.labelMedium?.copyWith(color: corTexto),
      ),
    );
  }
}
