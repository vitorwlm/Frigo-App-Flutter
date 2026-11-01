import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class ExpiringCard extends StatelessWidget {
  const ExpiringCard({super.key, required this.items, this.onVerTudo});

  final List<ExpiringItem> items;
  final VoidCallback? onVerTudo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('A expirar', style: textTheme.titleLarge),
            const SizedBox(width: 6),
            Text(
              '${items.length}',
              style: textTheme.titleMedium?.copyWith(color: AppColors.gray500),
            ),
            // Spacer ocupa o espaco que sobra
            const Spacer(),
            TextButton(
              onPressed: onVerTudo,
              child: const Text('Ver inventário'),
            ),
          ],
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: items),
        ),
      ],
    );
  }
}

class ExpiringItem extends StatelessWidget {
  const ExpiringItem({
    super.key,
    required this.nome,
    required this.quantidade,
    required this.dias,
    required this.onUsei,
    this.ultimo = false,
  });

  final String nome;
  final String quantidade;
  final int dias;
  final VoidCallback onUsei;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    String prazo;
    Color corBarra;
    Color corFundo;
    Color corTexto;
    if (dias == 0) {
      prazo = 'Hoje';
      corBarra = AppColors.danger500;
      corFundo = AppColors.danger100;
      corTexto = AppColors.danger700;
    } else if (dias == 1) {
      prazo = 'Amanhã';
      corBarra = AppColors.warning500;
      corFundo = AppColors.warning100;
      corTexto = AppColors.warning800;
    } else {
      prazo = '$dias dias';
      corBarra = AppColors.gray300;
      corFundo = AppColors.gray100;
      corTexto = AppColors.gray600;
    }

    return Container(
      // linha por baixo de cada item, menos no ultimo
      decoration: BoxDecoration(
        border: ultimo
            ? null
            : const Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 64, color: corBarra),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: textTheme.titleMedium),
                Text(
                  quantidade,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              prazo,
              style: textTheme.labelMedium?.copyWith(color: corTexto),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: onUsei,
            tooltip: 'Usei',
            icon: const Icon(Icons.check, color: AppColors.primary500),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
