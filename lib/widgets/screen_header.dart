import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'circle_icon_button.dart';

// Cabeçalho do Figma: subtítulo + título, voltar opcional e ações à direita
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.voltar = false,
    this.acoes = const [],
  });

  final String titulo;
  final String? subtitulo;
  final bool voltar;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        if (voltar) ...[
          CircleIconButton(
            icone: Icons.chevron_left,
            tooltip: 'Voltar',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.midsmall),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
              Text(titulo, style: textTheme.headlineMedium),
            ],
          ),
        ),
        // for dentro da lista: um espaço + a ação, para cada ação
        for (final acao in acoes) ...[
          const SizedBox(width: AppSpacing.small),
          acao,
        ],
      ],
    );
  }
}
