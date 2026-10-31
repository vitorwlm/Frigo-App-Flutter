import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.message,
    required this.temperature,
    // opcional, false por defeito
    this.isAlert = false,
  });

  final String message;
  final double temperature;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(
            isAlert ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: isAlert ? AppColors.danger500 : AppColors.success500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${temperature.toStringAsFixed(1)} °C',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }
}
