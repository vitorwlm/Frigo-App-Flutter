import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.midsmall),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  // ? = pode ser null; sem onTap o cartao nao reage ao toque
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        // ?? = se borderColor for null usa o contorno por defeito
        side: BorderSide(color: borderColor ?? AppTokens.border),
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
