import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'tag_chip.dart';

// tom=marca quando tens tudo, tom=aviso quando falta um ingrediente
enum ReceitaTom { marca, aviso }

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.estado,
    required this.minutos,
    this.tom = ReceitaTom.marca,
    this.mostrarFoto = true,
    this.onTap,
  });

  final String titulo;
  final String descricao;
  // texto do primeiro chip: "Tens tudo", "Falta farinha"…
  final String estado;
  final int minutos;
  final ReceitaTom tom;
  final bool mostrarFoto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool aviso = tom == ReceitaTom.aviso;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // lugar da foto da receita
            Container(
              width: 88,
              color: aviso ? AppTokens.bgWarning : AppTokens.bgTonal,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 30,
                    color: aviso ? AppColors.warning700 : AppColors.primary600,
                  ),
                  if (mostrarFoto) ...[
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      '[foto]',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.midsmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(titulo, style: textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    // Wrap passa os chips para a linha de baixo se não couberem
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        TagChip(
                          texto: estado,
                          tom: aviso ? TagTom.aviso : TagTom.marca,
                        ),
                        TagChip(texto: '$minutos min', tom: TagTom.contorno),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.midsmall),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
