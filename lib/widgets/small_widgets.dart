import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

// Motivo do ecrã Impacto: nome, número e barra
class ReasonBar extends StatelessWidget {
  const ReasonBar({
    super.key,
    required this.motivo,
    required this.valor,
    required this.fracao,
  });

  final String motivo;
  final int valor;
  // 0.0 a 1.0
  final double fracao;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.midsmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(motivo, style: textTheme.labelLarge)),
              Text(
                '$valor',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 8,
              backgroundColor: AppTokens.bgTrack,
              color: AppColors.danger600,
            ),
          ),
        ],
      ),
    );
  }
}

// Passo numerado da receita
class StepRow extends StatelessWidget {
  const StepRow({super.key, required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTokens.bgTonal,
          child: Text(
            '$numero',
            style: textTheme.labelMedium?.copyWith(color: AppTokens.textBrand),
          ),
        ),
        const SizedBox(width: AppSpacing.midsmall),
        Expanded(child: Text(texto, style: textTheme.bodyMedium)),
      ],
    );
  }
}

// Pontos do onboarding: o atual é mais comprido
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.total, required this.atual});

  final int total;
  final int atual;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < total; i++)
          // AnimatedContainer anima a mudança de largura e de cor
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == atual ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == atual ? AppColors.primary500 : AppTokens.bgTrack,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
