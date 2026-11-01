import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.etiqueta,
    required this.titulo,
    required this.minutos,
    required this.aExpirar,
    this.onTap,
  });

  final String etiqueta;
  final String titulo;
  final int minutos;
  final int aExpirar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // lugar da foto da receita
            Container(width: 104, color: AppColors.gray200),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      etiqueta,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primary600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(titulo, style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gray200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$minutos min', style: textTheme.labelMedium),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Usa $aExpirar a expirar',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.primary700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
