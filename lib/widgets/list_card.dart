import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

// Moldura branca das listas, com uma linha entre cada filho
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, thickness: 1, color: AppTokens.border),
          ],
        ],
      ),
    );
  }
}
