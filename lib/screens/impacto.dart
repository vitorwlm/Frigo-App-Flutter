import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/evento.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/hero_card.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/small_widgets.dart';
import '../widgets/snack.dart';
import '../widgets/tag_chip.dart';

// Estimativas para transformar kg em € e em CO2 (citar a fonte no relatório)
class Estimativas {
  static const double euroPorKg = 4;
  static const double co2PorKg = 2.5;
}

const List<String> _nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

enum Periodo { mes, ano }

// Ecrã 09 do Figma
class Impacto extends StatefulWidget {
  const Impacto({super.key});

  @override
  State<Impacto> createState() => _ImpactoState();
}

class _ImpactoState extends State<Impacto> {
  Periodo _periodo = Periodo.mes;

  // true se o evento for do mês (ou ano) que está a ver; recuar = 1 para o anterior
  bool _noPeriodo(Evento e, {int recuar = 0}) {
    final agora = DateTime.now();
    if (_periodo == Periodo.ano) return e.data.year == agora.year - recuar;
    final alvo = DateTime(agora.year, agora.month - recuar);
    return e.data.year == alvo.year && e.data.month == alvo.month;
  }

  // percentagem aproveitada; null se não houver dados
  double? _percentagem(List<Evento> eventos) {
    final usados = eventos.where((e) => e.tipo == TipoEvento.usado).length;
    final total = eventos.length;
    if (total == 0) return null;
    return usados / total * 100;
  }

  String _num(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: frigorifico,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        TextStyle? branco(TextStyle? s) =>
            s?.copyWith(color: AppTokens.textOnHero);

        final agora = DateTime.now();
        final eventos = frigorifico.eventos.where((e) => _noPeriodo(e)).toList();
        final anteriores =
            frigorifico.eventos.where((e) => _noPeriodo(e, recuar: 1)).toList();
        final usados = eventos.where((e) => e.tipo == TipoEvento.usado).toList();
        final fora = eventos.where((e) => e.tipo == TipoEvento.deitadoFora).toList();

        final double? pct = _percentagem(eventos);
        final double? pctAntes = _percentagem(anteriores);
        // fold = soma: começa em 0 e vai juntando o peso de cada evento
        final double kgSalvos = usados.fold(0.0, (soma, e) => soma + e.pesoKg);
        final double kgFora = fora.fold(0.0, (soma, e) => soma + e.pesoKg);

        // conta os motivos: {'Passou a validade': 3, ...}
        final Map<String, int> motivos = {};
        for (final e in fora) {
          final m = e.motivo ?? 'Outro';
          motivos[m] = (motivos[m] ?? 0) + 1;
        }
        final listaMotivos = motivos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // o alimento deitado fora mais vezes
        final Map<String, int> porNome = {};
        for (final e in fora) {
          porNome[e.nome] = (porNome[e.nome] ?? 0) + 1;
        }
        final maisDesperdicado = porNome.entries.isEmpty
            ? null
            : (porNome.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first;

        final String nomePeriodo = _periodo == Periodo.mes
            ? _nomesMeses[agora.month - 1]
            : '${agora.year}';
        final String nomeAnterior = _periodo == Periodo.mes
            ? _nomesMeses[(agora.month + 10) % 12].toLowerCase()
            : '${agora.year - 1}';

        String comparacao = '';
        if (pct != null && pctAntes != null) {
          final int dif = (pct - pctAntes).round();
          comparacao = '${dif >= 0 ? '+' : ''}$dif pp vs $nomeAnterior';
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.midsmall),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ScreenHeader(subtitulo: nomePeriodo, titulo: 'Impacto'),
                  ),
                  SegmentedButton<Periodo>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: Periodo.mes, label: Text('Mês')),
                      ButtonSegment(value: Periodo.ano, label: Text('Ano')),
                    ],
                    selected: {_periodo},
                    onSelectionChanged: (s) => setState(() => _periodo = s.first),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.midsmall),
              HeroCard(
                cor: AppTokens.heroOk,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroPill(texto: 'Aproveitado', icone: Icons.eco),
                    const SizedBox(height: AppSpacing.midsmall),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          pct == null ? '—' : '${pct.round()} %',
                          style: branco(textTheme.displayLarge),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Flexible(
                          child: Text(comparacao, style: branco(textTheme.labelLarge)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.midsmall),
                    if (pct != null)
                      // barra dividida: flex só aceita inteiros
                      Row(
                        children: [
                          if (pct.round() > 0)
                            Expanded(
                              flex: pct.round(),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                              ),
                            ),
                          if (pct.round() > 0 && pct.round() < 100)
                            const SizedBox(width: 4),
                          if (pct.round() < 100)
                            Expanded(
                              flex: 100 - pct.round(),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.danger300,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      '${usados.length} usados · ${fora.length} deitados fora · '
                      '${_num(kgFora)} kg',
                      style: branco(textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  _Equivalencia(valor: '${_num(kgSalvos)} kg', legenda: 'de comida salva'),
                  const SizedBox(width: AppSpacing.small),
                  _Equivalencia(
                    valor: '≈ ${(kgSalvos * Estimativas.euroPorKg).round()} €',
                    legenda: 'poupados',
                  ),
                  const SizedBox(width: AppSpacing.small),
                  _Equivalencia(
                    valor: '${(kgSalvos * Estimativas.co2PorKg).round()} kg',
                    legenda: 'de CO₂e evitado',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Estimativa: ${Estimativas.euroPorKg.round()} € e '
                '${_num(Estimativas.co2PorKg)} kg CO₂e por kg de comida.',
                style: textTheme.labelSmall?.copyWith(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: AppSpacing.mid),
              const SectionTitle(titulo: 'Porque deitas fora'),
              const SizedBox(height: AppSpacing.small),
              if (listaMotivos.isEmpty)
                AppCard(
                  child: Text(
                    'Nada deitado fora neste período.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textSecondary,
                    ),
                  ),
                )
              else
                ListCard(
                  children: [
                    for (final m in listaMotivos)
                      ReasonBar(
                        motivo: m.key,
                        valor: m.value,
                        // parte de todos os deitados fora
                        fracao: m.value / fora.length,
                      ),
                  ],
                ),
              if (maisDesperdicado != null) ...[
                const SizedBox(height: AppSpacing.mid),
                const SectionTitle(titulo: 'Mais desperdiçado'),
                const SizedBox(height: AppSpacing.small),
                ListCard(
                  children: [
                    ItemRow(
                      titulo: maisDesperdicado.key,
                      detalhe: '${maisDesperdicado.value} vezes · compra packs mais pequenos',
                      estado: EstadoValidade.perigo,
                      trailing: AppButton(
                        texto: 'Pack de 1',
                        tipo: BotaoTipo.tonal,
                        onPressed: () {
                          frigorifico.adicionarCompra(
                            '${maisDesperdicado.key} (pack de 1)',
                            'Pack mais pequeno',
                            tom: TagTom.aviso,
                          );
                          mostrarMensagem(context, 'Ficou na lista de compras');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Um dos 3 cartões por baixo do hero
class _Equivalencia extends StatelessWidget {
  const _Equivalencia({required this.valor, required this.legenda});

  final String valor;
  final String legenda;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.small),
        radius: AppRadius.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: textTheme.headlineSmall?.copyWith(color: AppTokens.textBrand),
            ),
            Text(
              legenda,
              style: textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
