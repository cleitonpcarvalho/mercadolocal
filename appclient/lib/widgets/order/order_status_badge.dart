import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, super.key});

  final String status;

  static const Map<String, Color> _statusColors = <String, Color>{
    'pending': AppColors.pending,
    'confirmed': AppColors.info,
    'preparing': AppColors.warning,
    'ready': AppColors.purple,
    'in_delivery': AppColors.primary,
    'delivered': AppColors.success,
    'cancelled': AppColors.danger,
  };
  static const Map<String, String> _statusLabels = <String, String>{
    'pending': 'Pendente',
    'confirmed': 'Confirmado',
    'preparing': 'Em preparação',
    'ready': 'Aguardando entregador',
    'in_delivery': 'Em entrega',
    'delivered': 'Entregue',
    'cancelled': 'Cancelado',
  };

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColors[status] ?? AppColors.gray500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(99),
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

  String _label(String value) {
    return _statusLabels[value] ?? 'Status';
  }
}
