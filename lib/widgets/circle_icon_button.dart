import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

// variantes "estilo" do Botão ícone do Figma
enum CirculoEstilo { superficie, contorno, preenchido, transparente }

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icone,
    required this.tooltip,
    required this.onPressed,
    this.estilo = CirculoEstilo.superficie,
    this.badge,
    this.corIcone,
  });

  final IconData icone;
  // texto lido pelo leitor de ecrã e mostrado ao carregar sem largar
  final String tooltip;
  final VoidCallback? onPressed;
  final CirculoEstilo estilo;
  // número vermelho no canto (ex.: avisos por ler)
  final String? badge;
  final Color? corIcone;

  @override
  Widget build(BuildContext context) {
    Color? fundo;
    Color frente = AppTokens.textPrimary;
    BorderSide? borda;
    double tamanho = 48;

    switch (estilo) {
      case CirculoEstilo.superficie:
        fundo = AppTokens.bgSurface;
        tamanho = 52;
      case CirculoEstilo.contorno:
        fundo = AppTokens.bgSurface;
        frente = AppColors.primary600;
        borda = const BorderSide(color: AppTokens.border, width: 1.5);
      case CirculoEstilo.preenchido:
        fundo = AppColors.primary500;
        frente = AppColors.white;
      case CirculoEstilo.transparente:
        fundo = null;
    }

    final Widget botao = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icone),
      style: IconButton.styleFrom(
        backgroundColor: fundo,
        foregroundColor: corIcone ?? frente,
        fixedSize: Size(tamanho, tamanho),
        side: borda,
      ),
    );

    if (badge == null) return botao;
    // Badge = bolinha com número, já vem no Material 3
    return Badge(
      label: Text(badge!),
      backgroundColor: AppColors.danger600,
      offset: const Offset(-4, 4),
      child: botao,
    );
  }
}
