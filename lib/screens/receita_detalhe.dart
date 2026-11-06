import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/receita.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/small_widgets.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';

// Ecrãs 08 e 23 do Figma: o mesmo ecrã, muda só o número de pessoas
class ReceitaDetalhe extends StatefulWidget {
  const ReceitaDetalhe({super.key, required this.receita});

  final Receita receita;

  @override
  State<ReceitaDetalhe> createState() => _ReceitaDetalheState();
}

class _ReceitaDetalheState extends State<ReceitaDetalhe> {
  // late = recebe o valor no initState, antes de ser usado
  late int _pessoas;

  @override
  void initState() {
    super.initState();
    _pessoas = widget.receita.pessoasBase;
  }

  // chip à direita de cada ingrediente
  TagChip _chip(Ingrediente i) {
    final double falta = i.falta(_pessoas);
    if (falta > 0) {
      final int f = falta.round();
      final String texto = i.porUnidade ? 'Falta $f' : 'Faltam $f ${i.unidade}';
      return TagChip(texto: texto, tom: TagTom.aviso);
    }
    if (i.despensa || i.dias == null) {
      return const TagChip(texto: 'Tens', tom: TagTom.marca);
    }
    return TagChip(texto: prazoDe(i.dias!), tom: tomDe(estadoDe(i.dias!)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Receita r = widget.receita;
    final emFalta = r.ingredientes.where((i) => i.falta(_pessoas) > 0).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          children: [
            ScreenHeader(
              voltar: true,
              subtitulo: '${r.minutos} min · $_pessoas pessoas',
              titulo: r.titulo,
            ),
            const SizedBox(height: AppSpacing.midsmall),
            // lugar da foto da receita
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTokens.bgTonal,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant,
                    size: 34,
                    color: AppColors.primary600,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    '[foto]',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            // tempo, dificuldade e quantos alimentos a expirar salva
            Row(
              children: [
                _Resumo(icone: Icons.schedule, valor: '${r.minutos} min', legenda: 'tempo'),
                const SizedBox(width: AppSpacing.small),
                _Resumo(icone: Icons.restaurant_menu, valor: r.dificuldade, legenda: 'dificuldade'),
                const SizedBox(width: AppSpacing.small),
                _Resumo(icone: Icons.eco_outlined, valor: '${r.salva}', legenda: 'a expirar salvos'),
              ],
            ),
            const SizedBox(height: AppSpacing.midsmall),
            // seletor de pessoas
            AppCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.midsmall,
                AppSpacing.small,
                AppSpacing.small,
                AppSpacing.small,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Pessoas', style: textTheme.labelLarge)),
                  CircleIconButton(
                    icone: Icons.remove,
                    tooltip: 'Menos pessoas',
                    estilo: CirculoEstilo.contorno,
                    onPressed:
                        _pessoas > 1 ? () => setState(() => _pessoas--) : null,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_pessoas',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  CircleIconButton(
                    icone: Icons.add,
                    tooltip: 'Mais pessoas',
                    estilo: CirculoEstilo.contorno,
                    onPressed:
                        _pessoas < 12 ? () => setState(() => _pessoas++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.mid),
            const SectionTitle(titulo: 'Ingredientes'),
            const SizedBox(height: AppSpacing.small),
            ListCard(
              children: [
                for (final i in r.ingredientes)
                  ItemRow(
                    titulo: i.texto(_pessoas),
                    estado: i.despensa
                        ? EstadoValidade.marca
                        : (i.dias == null
                            ? EstadoValidade.nenhum
                            : estadoDe(i.dias!)),
                    trailing: _chip(i),
                  ),
              ],
            ),
            // aviso do que falta (ecrã 23)
            if (emFalta.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.midsmall),
              Container(
                padding: const EdgeInsets.all(AppSpacing.midsmall),
                decoration: BoxDecoration(
                  color: AppTokens.bgWarning,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTokens.textWarning,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'Falta ${emFalta.map((i) => i.nome).join(', ')} '
                        'para $_pessoas pessoas',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppTokens.textWarning,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    AppButton(
                      texto: 'Às compras',
                      tipo: BotaoTipo.tonal,
                      onPressed: () {
                        for (final i in emFalta) {
                          frigorifico.adicionarCompra(
                            i.nome[0].toUpperCase() + i.nome.substring(1),
                            'Para ${r.titulo.toLowerCase()}',
                            tom: TagTom.marca,
                          );
                        }
                        mostrarMensagem(context, 'Ficou na lista de compras');
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.mid),
            const SectionTitle(titulo: 'Passos'),
            const SizedBox(height: AppSpacing.small),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.mid),
              child: Column(
                children: [
                  for (int n = 0; n < r.passos.length; n++) ...[
                    if (n > 0) const SizedBox(height: AppSpacing.midsmall),
                    StepRow(numero: n + 1, texto: r.passos[n]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.midsmall),
          child: AppButton(
            texto: 'Cozinhei esta receita',
            expandir: true,
            // sem os ingredientes todos o botão fica desativado
            onPressed: emFalta.isEmpty
                ? () {
                    frigorifico.cozinhar(r, _pessoas);
                    mostrarMensagem(
                      context,
                      'Bom apetite! Os ingredientes saíram do inventário.',
                    );
                    Navigator.pop(context);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

// Um dos 3 cartões de resumo da receita
class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.icone,
    required this.valor,
    required this.legenda,
  });

  final IconData icone;
  final String valor;
  final String legenda;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Expanded: os 3 cartões ficam com a mesma largura
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.small),
        radius: AppRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 20, color: AppColors.primary600),
            const SizedBox(height: 4),
            Text(valor, style: textTheme.labelLarge),
            Text(
              legenda,
              style: textTheme.bodySmall?.copyWith(
                color: AppTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
