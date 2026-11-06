import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

// Cartão grande e colorido do topo dos ecrãs
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.cor, required this.child, this.onTap});

  final Color cor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Material + InkWell = fundo com cantos e efeito de toque
    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.mid),
          child: child,
        ),
      ),
    );
  }
}

// Pílula translúcida com ícone dentro do HeroCard ("Tudo bem", "Porta aberta"…)
class HeroPill extends StatelessWidget {
  const HeroPill({super.key, required this.texto, required this.icone});

  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.heroOverlay,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 20, color: AppTokens.textOnHero),
          const SizedBox(width: AppSpacing.small),
          Text(
            texto,
            style: textTheme.labelLarge?.copyWith(color: AppTokens.textOnHero),
          ),
        ],
      ),
    );
  }
}
