import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(status),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'waiting':
        return AppColors.waiting;
      case 'accepted':
        return AppColors.accepted;
      case 'picked_up':
        return AppColors.pickedUp;
      case 'delivered':
        return AppColors.delivered;
      case 'failed':
        return AppColors.failed;
      default:
        return AppColors.gray500;
    }
  }

  String _label(String value) {
    switch (value) {
      case 'waiting':
        return 'Aguardando';
      case 'accepted':
        return 'Aceita';
      case 'picked_up':
        return 'Em rota';
      case 'delivered':
        return 'Entregue';
      case 'failed':
        return 'Falhou';
      default:
        return 'Status';
    }
  }
}
