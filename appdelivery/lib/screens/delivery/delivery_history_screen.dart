import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/delivery/delivery_status_badge.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<DeliveryProvider>().loadHistory();
  }

  List<DeliveryModel> _filteredList(List<DeliveryModel> history) {
    if (_filter == 'all') return history;
    return history
        .where((DeliveryModel item) => item.status == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final DeliveryProvider provider = context.watch<DeliveryProvider>();

    final List<DeliveryModel> filtered = _filteredList(
      provider.deliveryHistory,
    );
    final double totalEarnings = provider.deliveryHistory
        .where((DeliveryModel item) => item.status == 'delivered')
        .fold<double>(
          0,
          (double sum, DeliveryModel item) => sum + item.resolvedDeliveryFee,
        );

    if (provider.isLoading && provider.deliveryHistory.isEmpty) {
      return const LoadingWidget(message: 'Carregando histórico...');
    }

    if (provider.error != null && provider.deliveryHistory.isEmpty) {
      return _ErrorView(message: provider.error!, onRetry: _load);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildSummaryCard(totalEarnings),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const EmptyStateWidget(
              title: 'Nenhuma entrega realizada ainda',
              subtitle: 'Suas entregas concluídas aparecerão aqui.',
              icon: Icons.history_toggle_off_outlined,
            )
          else
            ...filtered.map(_buildHistoryItem),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalEarnings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Ganhos totais', style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(totalEarnings),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Soma das taxas das entregas concluídas',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: <Widget>[
        _filterChip(label: 'Todos', value: 'all'),
        const SizedBox(width: 8),
        _filterChip(label: 'Entregues', value: 'delivered'),
        const SizedBox(width: 8),
        _filterChip(label: 'Falhas', value: 'failed'),
      ],
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final bool selected = _filter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppColors.primary.withAlpha(20),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.gray300),
    );
  }

  Widget _buildHistoryItem(DeliveryModel delivery) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    delivery.storeName ?? 'Loja',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DeliveryStatusBadge(status: delivery.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Endereço: ${delivery.resolvedDeliveryAddress}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 2),
            Text(
              'Data: ${Formatters.dateTime(delivery.deliveredAt ?? delivery.createdAt)}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 2),
            Text(
              'Taxa recebida: ${Formatters.currency(delivery.resolvedDeliveryFee)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text('Avaliação recebida: -', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
