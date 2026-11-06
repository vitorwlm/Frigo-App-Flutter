import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

// Gráfico do ecrã 20: linha da temperatura, faixa do alvo,
// linhas tracejadas nas aberturas da porta e ponto vermelho no máximo
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    super.key,
    required this.leituras,
    required this.portas,
    required this.alvoMin,
    required this.alvoMax,
    required this.etiqueta,
  });

  // (momento, °C), do mais antigo para agora
  final List<(DateTime, double)> leituras;
  // momentos em que a porta abriu
  final List<DateTime> portas;
  final double alvoMin;
  final double alvoMax;
  // texto do eixo de baixo para um momento ("06:00", "seg"…), ou null
  final String? Function(DateTime t) etiqueta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final estiloEixo = textTheme.labelSmall?.copyWith(
      color: AppTokens.textSecondary,
    );

    final DateTime inicio = leituras.first.$1;
    // x = minutos desde a primeira leitura
    double x(DateTime t) => t.difference(inicio).inMinutes.toDouble();

    final pontos = [for (final l in leituras) FlSpot(x(l.$1), l.$2)];
    final double maxX = pontos.last.x;
    // reduce = compara todos e fica com o maior
    final FlSpot maximo = pontos.reduce((a, b) => b.y > a.y ? b : a);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: 10,
        borderData: FlBorderData(show: false),
        // linhas cinzentas só nos 2, 5 e 8 °C
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          checkToShowHorizontalLine: (v) => v == 2 || v == 5 || v == 8,
          getDrawingHorizontalLine: (v) =>
              const FlLine(color: AppTokens.border, strokeWidth: 1),
        ),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: alvoMin,
              y2: alvoMax,
              color: AppTokens.bgTonalSoft,
            ),
          ],
        ),
        // tracejado âmbar em cada abertura da porta
        extraLinesData: ExtraLinesData(
          verticalLines: [
            for (final p in portas)
              if (!p.isBefore(inicio))
                VerticalLine(
                  x: x(p),
                  color: AppTokens.statusWarning,
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 1,
              getTitlesWidget: (v, meta) => (v == 2 || v == 5 || v == 8)
                  ? Text('${v.toInt()} °C', style: estiloEixo)
                  : const SizedBox.shrink(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              // um teste por leitura; só alguns têm texto
              interval: pontos.length > 1 ? pontos[1].x - pontos[0].x : 1,
              getTitlesWidget: (v, meta) {
                if (v == maxX) return Text('agora', style: estiloEixo);
                // perto do fim não cabe (sobrepunha-se ao "agora")
                if (v > maxX * 0.9) return const SizedBox.shrink();
                final texto =
                    etiqueta(inicio.add(Duration(minutes: v.toInt())));
                return texto == null
                    ? const SizedBox.shrink()
                    : Text(texto, style: estiloEixo);
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            color: AppTokens.statusBrand,
            barWidth: 2.5,
            // ponto só no máximo
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, bar) => spot == maximo,
              getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                radius: 5,
                color: AppTokens.statusDanger,
                strokeWidth: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
