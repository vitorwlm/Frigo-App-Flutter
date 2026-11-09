import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

// * Etiqueta pequena (componente Chip do Figma): prazos, "Tens tudo",
// * motivos das compras… O tom diz a urgência pela cor; o texto diz o mesmo
// * em palavras, para não depender só da cor.

// ? enum = lista fechada de opções (como as variantes "tom" do Figma)
enum TagTom { perigo, aviso, neutro, marca, contorno, contornoHero }

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.texto, this.tom = TagTom.neutro});

  final String texto;
  final TagTom tom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ? fundo e borda podem ficar null (sem fundo / sem contorno);
    // ? corTexto é sempre definido, o compilador garante-o pelo switch
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
