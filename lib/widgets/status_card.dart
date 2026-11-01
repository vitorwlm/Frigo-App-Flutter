import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.status,
    required this.temperature,
    required this.humidity,
    required this.detalhe,
    this.isAlert = false,
    this.onTap,
  });

  final String status;
  final double temperature;
  final double humidity;
  final String detalhe;
  final bool isAlert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // vai buscar os estilos de texto do tema
    final textTheme = Theme.of(context).textTheme;

    final Color corFundo = isAlert ? AppColors.danger600 : AppColors.primary600;
    final Color corChip = isAlert ? AppColors.danger500 : AppColors.primary500;
    final Color corSecundaria = isAlert
        ? AppColors.danger100
        : AppColors.primary200;
    final IconData icone = isAlert
        ? Icons.warning_amber_rounded
        : Icons.check_circle;

    return AppCard(
      onTap: onTap,
      color: corFundo,
      borderColor: corFundo,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            // BoxDecoration = fundo e cantos do Container
            decoration: BoxDecoration(
              color: corChip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              // a Row fica so do tamanho do conteudo
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  status,
                  // ?. so chama o copyWith se o estilo nao for null
                  // copyWith copia o estilo e muda so o que se indica
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // toStringAsFixed(1) = uma casa decimal
                    temperature.toStringAsFixed(1),
                    style: textTheme.headlineLarge?.copyWith(
                      fontSize: 56,
                      height: 1,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '°C',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Icon(Icons.water_drop, size: 18, color: corSecundaria),
              const SizedBox(width: 4),
              Text(
                '${humidity.toStringAsFixed(0)} %',
                style: textTheme.titleMedium?.copyWith(color: corSecundaria),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detalhe,
            style: textTheme.bodySmall?.copyWith(color: corSecundaria),
          ),
        ],
      ),
    );
  }
}
