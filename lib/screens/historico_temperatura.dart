// * ECRÃ HISTÓRICO DA TEMPERATURA (ecrã 20 do Figma). Abre pelo cartão de
// * cima do Início ("Detalhes" / "Histórico").
// * Fluxo: 24 h / 7 dias → gráfico com a faixa do alvo e as aberturas da
// * porta → mínima, média, máxima → lista das aberturas e o efeito de cada.
// * As leituras vêm do frigorifico (Supabase, ou falsas sem a placa).

import 'package:flutter/material.dart';

import '../data/frigorifico.dart';
import '../models/evento.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/history_chart.dart';
import '../widgets/item_row.dart';
import '../widgets/list_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_title.dart';
import '../widgets/tag_chip.dart';

// ! nome diferente do Periodo do Impacto para não chocarem nos imports
enum Periodo24 { dia, semana }

const List<String> _diasSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

// ? "09:05": padLeft põe o 0 à esquerda
String _hora(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// ? aberturas curtas em segundos, as longas em minutos
String _duracao(Duration d) =>
    d.inSeconds < 60 ? '${d.inSeconds} s' : '${d.inMinutes} min';

// ? StatefulWidget porque guarda o período escolhido
class HistoricoTemperatura extends StatefulWidget {
  const HistoricoTemperatura({super.key});

  @override
  State<HistoricoTemperatura> createState() => _HistoricoTemperaturaState();
}

class _HistoricoTemperaturaState extends State<HistoricoTemperatura> {
  Periodo24 _periodo = Periodo24.dia;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final f = frigorifico;
    final bool dia = _periodo == Periodo24.dia;

    // ? 24 h: de 30 em 30 min · 7 dias: de hora a hora (pontos suficientes
    // ? para a linha, sem encher o gráfico)
    final leituras = dia ? f.leituras(24, 30) : f.leituras(24 * 7, 60);
    final valores = [for (final l in leituras) l.$2];
    final double minimo = valores.reduce((a, b) => a < b ? a : b);
    final double maximo = valores.reduce((a, b) => a > b ? a : b);
    // ? fold = soma tudo a começar em 0
    final double media = valores.fold(0.0, (s, v) => s + v) / valores.length;

    final DateTime desde = leituras.first.$1;
    // ? só as aberturas dentro do período do gráfico, mais recentes primeiro
    final aberturas = f.aberturas.where((a) => !a.inicio.isBefore(desde)).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));

    final bool noAlvo = f.temperatura >= f.alvoMin && f.temperatura <= f.alvoMax;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.midsmall,
            AppSpacing.midsmall,
            AppSpacing.midsmall,
            AppSpacing.mid,
          ),
          children: [
            ScreenHeader(
              subtitulo: dia ? 'Últimas 24 h' : 'Últimos 7 dias',
              titulo: 'Temperatura',
              voltar: true,
            ),
            const SizedBox(height: AppSpacing.midsmall),
            SegmentedButton<Periodo24>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: Periodo24.dia, label: Text('24 h')),
                ButtonSegment(value: Periodo24.semana, label: Text('7 dias')),
              ],
              selected: {_periodo},
              onSelectionChanged: (s) => setState(() => _periodo = s.first),
            ),
            const SizedBox(height: AppSpacing.midsmall),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(graus(f.temperatura), style: textTheme.headlineMedium),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'agora',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTokens.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      TagChip(
                        texto: noAlvo ? 'Dentro do alvo' : 'Fora do alvo',
                        tom: noAlvo ? TagTom.marca : TagTom.perigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  SizedBox(
                    height: 170,
                    child: HistoryChart(
                      leituras: leituras,
                      portas: [for (final a in f.aberturas) a.inicio],
                      alvoMin: f.alvoMin,
                      alvoMax: f.alvoMax,
                      etiqueta: (t) {
                        if (dia) {
                          // ? só a primeira leitura depois das 0, 6, 12 e 18 h,
                          // ? para o eixo ter 4 etiquetas e não 48
                          return t.hour % 6 == 0 && t.minute < 30
                              ? '${t.hour.toString().padLeft(2, '0')}:00'
                              : null;
                        }
                        // ? weekday: 1 = segunda … 7 = domingo; uma etiqueta
                        // ? por dia (à meia-noite)
                        return t.hour == 0 ? _diasSemana[t.weekday - 1] : null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.midsmall,
                    runSpacing: AppSpacing.small,
                    children: [
                      _Legenda(
                        cor: AppTokens.bgTonalSoft,
                        texto: 'Alvo ${numeroPt(f.alvoMin)}–${numeroPt(f.alvoMax)} °C',
                      ),
                      const _Legenda(
                        cor: AppTokens.statusWarning,
                        texto: 'Porta aberta',
                      ),
                      const _Legenda(cor: AppTokens.statusDanger, texto: 'Máximo'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.midsmall),
            Row(
              children: [
                Expanded(child: _Resumo(titulo: 'Mínima', valor: graus(minimo))),
                const SizedBox(width: AppSpacing.small),
                Expanded(child: _Resumo(titulo: 'Média', valor: graus(media))),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: _Resumo(
                    titulo: 'Máxima',
                    valor: graus(maximo),
                    alerta: maximo > f.alvoMax,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.midsmall),
            SectionTitle(titulo: 'Aberturas da porta', contador: aberturas.length),
            const SizedBox(height: AppSpacing.midsmall),
            if (aberturas.isEmpty)
              Text(
                'A porta não foi aberta neste período.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondary,
                ),
              )
            else
              ListCard(
                children: [
                  for (final a in aberturas) _linhaAbertura(a, dia),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ? Cada abertura diz quanto aqueceu: > alvo+1 é perigo (vermelho), para
  // ? a pessoa perceber que deixar a porta aberta estraga a comida
  Widget _linhaAbertura(AberturaPorta a, bool dia) {
    final f = frigorifico;
    String detalhe;
    EstadoValidade estado = EstadoValidade.neutro;
    if (a.maxTemp > f.alvoMax + 1) {
      detalhe = 'Chegou a ${graus(a.maxTemp)}';
      estado = EstadoValidade.perigo;
    } else if (a.maxTemp > f.alvoMax) {
      detalhe = 'Subiu até ${graus(a.maxTemp)}';
    } else {
      detalhe = 'Sem efeito na temperatura';
    }
    final String quando = dia
        ? _hora(a.inicio)
        : '${_diasSemana[a.inicio.weekday - 1]} ${_hora(a.inicio)}';

    return ItemRow(
      titulo: '$quando · ${_duracao(a.duracao)}',
      detalhe: detalhe,
      estado: estado,
    );
  }
}

// ? quadrado de cor + texto, para explicar as cores do gráfico
class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ? Mínima / Média / Máxima; a máxima fica vermelha se passou o alvo
class _Resumo extends StatelessWidget {
  const _Resumo({required this.titulo, required this.valor, this.alerta = false});

  final String titulo;
  final String valor;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.midsmall,
        vertical: AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
          ),
          Text(
            valor,
            style: textTheme.labelLarge?.copyWith(
              color: alerta ? AppTokens.textDanger : null,
            ),
          ),
        ],
      ),
    );
  }
}
