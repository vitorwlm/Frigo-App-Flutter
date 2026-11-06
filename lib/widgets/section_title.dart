import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.titulo, this.contador});

  final String titulo;
  final int? contador;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      // alinha os dois textos pela linha de base das letras
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(titulo, style: textTheme.headlineSmall),
        if (contador != null) ...[
          const SizedBox(width: AppSpacing.small),
          Text(
            '$contador',
            style: textTheme.headlineSmall?.copyWith(
              color: AppTokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
