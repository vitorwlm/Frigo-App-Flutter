import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

// ? Cartão pequeno do layout antigo do Início (antes de 1 nov). Já não é
// ? usado em nenhum ecrã: pode ser apagado.
class SmallCard extends StatelessWidget {
  const SmallCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(label, style: textTheme.titleMedium),
          Icon(icon, color: AppColors.primary500),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
