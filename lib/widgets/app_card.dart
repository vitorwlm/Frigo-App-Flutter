import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  // ? = pode ser null; sem onTap o cartao nao reage ao toque
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // ?? = se borderColor for null usa o gray200
        side: BorderSide(color: borderColor ?? AppColors.gray200),
      ),
      // corta o efeito de toque nos cantos arredondados
      clipBehavior: Clip.antiAlias,
      // InkWell torna o cartao clicavel com o efeito de toque
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
