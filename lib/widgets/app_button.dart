import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// as variantes "type" e os 3 conjuntos (primary, accent, neutral) do Figma
enum BotaoTipo { fill, tonal, ghost, stroke }

enum BotaoCor { primary, accent, neutral }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.tipo = BotaoTipo.fill,
    this.cor = BotaoCor.primary,
    this.icone,
    this.expandir = false,
  });

  final String texto;
  // null = botão desativado
  final VoidCallback? onPressed;
  final BotaoTipo tipo;
  final BotaoCor cor;
  final IconData? icone;
  // true = ocupa a largura toda
  final bool expandir;

  @override
  Widget build(BuildContext context) {
    // conteúdo igual para todos: ícone opcional + texto
    final Widget conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 20),
          const SizedBox(width: AppSpacing.small),
        ],
        Text(texto),
      ],
    );

    Widget botao;
    switch (tipo) {
      case BotaoTipo.fill:
        Color fundo = AppColors.primary500;
        Color frente = AppColors.white;
        if (cor == BotaoCor.accent) {
          // danger600 e não 500: o branco sobre o 500 não chega ao contraste mínimo
          fundo = AppColors.danger600;
        } else if (cor == BotaoCor.neutral) {
          fundo = AppColors.gray100;
          frente = AppColors.gray900;
        }
        botao = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: fundo,
            foregroundColor: frente,
          ),
          child: conteudo,
        );
      case BotaoTipo.tonal:
        botao = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary200,
            foregroundColor: AppColors.primary700,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.midsmall),
          ),
          child: conteudo,
        );
      case BotaoTipo.ghost:
        Color frente = AppColors.primary500;
        if (cor == BotaoCor.accent) frente = AppColors.danger600;
        if (cor == BotaoCor.neutral) frente = AppColors.gray900;
        botao = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: frente),
          child: conteudo,
        );
      case BotaoTipo.stroke:
        Color frente = AppColors.primary500;
        Color borda = AppColors.primary500;
        if (cor == BotaoCor.accent) {
          frente = AppColors.danger600;
          borda = AppColors.danger500;
        } else if (cor == BotaoCor.neutral) {
          frente = AppColors.gray900;
          borda = AppColors.gray400;
        }
        botao = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: frente,
            side: BorderSide(color: borda, width: 1.5),
          ),
          child: conteudo,
        );
    }

    if (expandir) {
      return SizedBox(width: double.infinity, child: botao);
    }
    return botao;
  }
}
