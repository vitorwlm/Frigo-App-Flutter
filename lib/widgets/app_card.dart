import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child; //para poder controlar posicoes internas a vontade
  // opcional: sem onTap o cartão não é clicável
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      // o efeito do toque não sai dos cantos
      clipBehavior: Clip.antiAlias,
      // InkWell: área clicável com o efeito de toque do Material
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
