import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/order/order_status_badge.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final MarketService _marketService = const MarketService();

  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  List<OrderModel> _orders = <OrderModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<OrderModel> orders = _selectedStatus == 'all'
          ? await _marketService.getOrders()
          : await _marketService.getOrdersByStatus(_selectedStatus);

      if (!mounted) return;
      setState(() {
        _orders = orders;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/search');
      case 2:
        context.go('/orders');
      case 3:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          title: const Text('Pedidos'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.gray900,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const EmptyStateWidget(
                title: 'Entre para ver seus pedidos',
                subtitle: 'Seu historico de compras aparece aqui.',
                icon: Icons.lock_outline,
              ),
              AppButton(
                label: 'Ir para login',
                onPressed: () => context.go('/login?next=%2Forders'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Meus pedidos'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: _onBottomNavTap,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: <Widget>[
                  Text('Filtrar status:', style: AppTextStyles.caption),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    underline: const SizedBox.shrink(),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'all', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pendente'),
                      ),
                      DropdownMenuItem(
                        value: 'confirmed',
                        child: Text('Confirmado'),
                      ),
                      DropdownMenuItem(
                        value: 'preparing',
                        child: Text('Em preparação'),
                      ),
                      DropdownMenuItem(
                        value: 'ready',
                        child: Text('Aguardando entregador'),
                      ),
                      DropdownMenuItem(
                        value: 'in_delivery',
                        child: Text('Em entrega'),
                      ),
                      DropdownMenuItem(
                        value: 'delivered',
                        child: Text('Entregue'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelado'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) return;
                      setState(() {
                        _selectedStatus = value;
                      });
                      _load();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }

    if (_orders.isEmpty) {
      return const EmptyStateWidget(
        title: 'Nenhum pedido encontrado',
        subtitle: 'Seus pedidos aparecerão aqui após a primeira compra.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, int index) {
        final OrderModel order = _orders[index];

        return InkWell(
          onTap: () => context.go('/orders/${order.id}'),
          borderRadius: BorderRadius.circular(14),
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
                        order.storeName,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Pedido #${order.id}', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(order.createdAt),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(order.total),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: _orders.length,
    );
  }
}
