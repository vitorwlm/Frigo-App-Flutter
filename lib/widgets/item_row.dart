import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'tag_chip.dart';

// cor da barra à esquerda (variante "estado" da Linha de lista no Figma)
enum EstadoValidade { perigo, aviso, neutro, marca, nenhum }

// Regra única para os prazos, usada em todos os ecrãs
EstadoValidade estadoDe(int dias) {
  if (dias <= 0) return EstadoValidade.perigo;
  if (dias <= 2) return EstadoValidade.aviso;
  return EstadoValidade.neutro;
}

String prazoDe(int dias) {
  if (dias <= 0) return 'Hoje';
  if (dias == 1) return 'Amanhã';
  return '$dias dias';
}

TagTom tomDe(EstadoValidade estado) {
  switch (estado) {
    case EstadoValidade.perigo:
      return TagTom.perigo;
    case EstadoValidade.aviso:
      return TagTom.aviso;
    case EstadoValidade.marca:
      return TagTom.marca;
    case EstadoValidade.neutro:
    case EstadoValidade.nenhum:
      return TagTom.neutro;
  }
}

class ItemRow extends StatelessWidget {
  const ItemRow({
    super.key,
    required this.titulo,
    this.detalhe,
    this.chip,
    this.estado = EstadoValidade.nenhum,
    this.leading,
    this.riscado = false,
    this.trailing,
    this.acoes,
    this.onTap,
  });

  // o que fica à esquerda do texto (ex.: CategoryAvatar)
  final Widget? leading;
  // título riscado e cinzento (ex.: no carrinho)
  final bool riscado;

  final String titulo;
  final String? detalhe;
  final Widget? chip;
  final EstadoValidade estado;
  // o que fica à direita: botão Usei, seta, chip, círculo de marcar…
  final Widget? trailing;
  // linha de botões por baixo do texto (ecrã Avisos)
  final Widget? acoes;
  final VoidCallback? onTap;

  Color? get _corBarra {
    switch (estado) {
      case EstadoValidade.perigo:
        return AppTokens.statusDanger;
      case EstadoValidade.aviso:
        return AppTokens.statusWarning;
      case EstadoValidade.neutro:
        return AppTokens.statusNeutral;
      case EstadoValidade.marca:
        return AppTokens.statusBrand;
      case EstadoValidade.nenhum:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool temMeta = chip != null || detalhe != null;

    return InkWell(
      onTap: onTap,
      // IntrinsicHeight deixa a barra de cor ter a altura da linha
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _corBarra ?? Colors.transparent),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    AppSpacing.small,
                    AppSpacing.small,
                    AppSpacing.small,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              titulo,
                              style: riscado
                                  ? textTheme.labelLarge?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppTokens.textSecondary,
                                    )
                                  : textTheme.labelLarge,
                            ),
                            if (temMeta) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (chip != null) ...[
                                    chip!,
                                    const SizedBox(width: AppSpacing.small),
                                  ],
                                  if (detalhe != null)
                                    // Flexible deixa o texto encolher sem sair do ecrã
                                    Flexible(
                                      child: Text(
                                        detalhe!,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppTokens.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (acoes != null) ...[
                              const SizedBox(height: AppSpacing.small),
                              acoes!,
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.small),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Círculo com o ícone da categoria (Avatar da Linha de lista no Figma)
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.icone});

  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTokens.bgTonalSoft,
      child: Icon(icone, size: 22, color: AppTokens.textBrand),
    );
  }
}
