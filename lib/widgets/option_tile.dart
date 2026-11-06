import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

enum OpcaoTom { marca, suave, neutro }

// Opção das folhas de baixo (Adicionar alimento, Partilhar lista)
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
    this.tom = OpcaoTom.marca,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;
  final OpcaoTom tom;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color fundo = AppTokens.bgTonal;
    Color corIcone = AppColors.primary600;
    if (tom == OpcaoTom.suave) fundo = AppTokens.bgTonalSoft;
    if (tom == OpcaoTom.neutro) {
      fundo = AppTokens.bgSubtle;
      corIcone = AppTokens.textPrimary;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.midsmall),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icone, color: corIcone),
            ),
            const SizedBox(width: AppSpacing.midsmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: textTheme.labelLarge),
                  Text(
                    descricao,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray600),
          ],
        ),
      ),
    );
  }
}
