import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/temperature_chart.dart';

class Detalhes extends StatelessWidget {
  const Detalhes({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.arrow_back),
                      // pop fecha este ecra e volta ao anterior
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text('Detalhes', style: textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Temperatura', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '4.2 °C',
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppColors.primary500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Últimas 24 h · alvo 2–5 °C',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        height: 180,
                        child: TemperatureChart(
                          valores: [
                            4.1, 4.3, 4.0, 3.8, 4.5, 6.2,
                            5.1, 4.4, 4.2, 4.0, 4.3, 4.2,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Estado', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                const AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      EstadoItem(
                        icon: Icons.water_drop,
                        label: 'Humidade',
                        value: '62 %',
                      ),
                      EstadoItem(
                        icon: Icons.door_front_door,
                        label: 'Porta',
                        value: 'Fechada',
                      ),
                      EstadoItem(
                        icon: Icons.air,
                        label: 'Ventoinha',
                        value: 'Desligada',
                      ),
                      EstadoItem(
                        icon: Icons.camera_alt,
                        label: 'Câmara',
                        value: 'Ligada',
                        ultimo: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class EstadoItem extends StatelessWidget {
  const EstadoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.ultimo = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: ultimo
            ? null
            : const Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary500),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
