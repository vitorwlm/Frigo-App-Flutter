import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TemperatureChart extends StatelessWidget {
  const TemperatureChart({
    super.key,
    required this.valores,
    this.alvoMin = 2,
    this.alvoMax = 5,
  });

  final List<double> valores;
  final double alvoMin;
  final double alvoMax;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // FlSpot(x, y) = um ponto do grafico; x e a posicao, y a temperatura
    final List<FlSpot> pontos = [];
    for (int i = 0; i < valores.length; i++) {
      pontos.add(FlSpot(i.toDouble(), valores[i]));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 10,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // faixa verde por tras da linha = zona alvo
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: alvoMin,
              y2: alvoMax,
              color: AppColors.success100,
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 2,
              // funcao que o grafico chama para desenhar cada numero do eixo
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.gray500,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: true,
            color: AppColors.primary500,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
