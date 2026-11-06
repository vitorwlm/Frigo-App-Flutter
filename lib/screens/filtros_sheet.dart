import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/list_card.dart';

enum Ordem { validade, nome, recentes }

const List<String> todasCategorias = [
  'Laticínios',
  'Ovos',
  'Legumes',
  'Sobras',
  'Carne e peixe',
  'Outros',
];

class Filtros {
  Filtros({
    this.ordem = Ordem.validade,
    this.soAbertos = false,
    this.soIncertos = false,
    Set<String>? categorias,
  }) : categorias = categorias ?? <String>{};
  // ↑ lista de inicialização: corre antes do corpo do construtor

  Ordem ordem;
  bool soAbertos;
  bool soIncertos;
  Set<String> categorias;

  // quantos filtros estão ligados (para o número no botão do cabeçalho)
  int get ativos =>
      (soAbertos ? 1 : 0) + (soIncertos ? 1 : 0) + categorias.length;

  Filtros copia() => Filtros(
    ordem: ordem,
    soAbertos: soAbertos,
    soIncertos: soIncertos,
    categorias: {...categorias},
  );
}

// Abre a folha (ecrã 21) e devolve os filtros escolhidos, ou null se fechar
Future<Filtros?> mostrarFiltros(
  BuildContext context,
  Filtros atuais,
  int Function(Filtros) contar,
) {
  // trabalha numa cópia: se fechar sem "Ver", nada muda
  final Filtros f = atuais.copia();

  return showModalBottomSheet<Filtros>(
    context: context,
    // deixa a folha ser mais alta que meio ecrã
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppTokens.bgApp,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      // StatefulBuilder dá um setState só para a folha
      return StatefulBuilder(
        builder: (context, setFolha) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.midsmall,
                0,
                AppSpacing.midsmall,
                AppSpacing.midsmall,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ordenar e filtrar', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.midsmall),
                  Text('Ordenar por', style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.small),
                  SegmentedButton<Ordem>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: Ordem.validade, label: Text('Validade')),
                      ButtonSegment(value: Ordem.nome, label: Text('Nome')),
                      ButtonSegment(value: Ordem.recentes, label: Text('Recentes')),
                    ],
                    selected: {f.ordem},
                    onSelectionChanged: (s) => setFolha(() => f.ordem = s.first),
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  Text('Mostrar só', style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.small),
                  ListCard(
                    children: [
                      SwitchListTile(
                        title: const Text('Abertos'),
                        subtitle: const Text('Iogurte, leite…'),
                        value: f.soAbertos,
                        onChanged: (v) => setFolha(() => f.soAbertos = v),
                      ),
                      SwitchListTile(
                        title: const Text('Os que a câmara não tem a certeza'),
                        subtitle: const Text('Para confirmares'),
                        value: f.soIncertos,
                        onChanged: (v) => setFolha(() => f.soIncertos = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.midsmall),
                  Text('Categorias', style: textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      for (final c in todasCategorias)
                        FilterChip(
                          label: Text(c),
                          selected: f.categorias.contains(c),
                          onSelected: (sim) => setFolha(() {
                            if (sim) {
                              f.categorias.add(c);
                            } else {
                              f.categorias.remove(c);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.mid),
                  Row(
                    children: [
                      AppButton(
                        texto: 'Limpar',
                        tipo: BotaoTipo.ghost,
                        onPressed: () => setFolha(() {
                          f.ordem = Ordem.validade;
                          f.soAbertos = false;
                          f.soIncertos = false;
                          f.categorias.clear();
                        }),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: AppButton(
                          texto: 'Ver ${contar(f)} alimentos',
                          expandir: true,
                          // devolve os filtros a quem abriu a folha
                          onPressed: () => Navigator.pop(context, f),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
