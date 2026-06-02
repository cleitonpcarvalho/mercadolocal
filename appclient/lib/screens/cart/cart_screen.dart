import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final MarketService _marketService = const MarketService();
  final TextEditingController _addressController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final CartProvider cartProvider = context.read<CartProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (!authProvider.isAuthenticated) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Voce precisa entrar para finalizar o pedido.'),
        ),
      );
      context.go('/login?next=%2Fcart');
      return;
    }

    if (cartProvider.items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Seu carrinho esta vazio.'),
        ),
      );
      return;
    }

    if (cartProvider.deliveryAddress.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Informe o endereco de entrega.'),
        ),
      );
      return;
    }

    final LatLng? location = cartProvider.deliveryLocation;
    if (location == null) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Selecione o ponto de entrega no mapa.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = await _marketService.createOrder(<String, dynamic>{
        'store': cartProvider.storeId,
        'items': cartProvider.items
            .map(
              (item) => <String, dynamic>{
                'product': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'delivery_address': cartProvider.deliveryAddress,
        'delivery_latitude': location.latitude,
        'delivery_longitude': location.longitude,
        'payment_method': cartProvider.paymentMethod,
        'notes': '',
      });

      if (!mounted) return;
      cartProvider.clearCart();

      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Pedido criado com sucesso.'),
        ),
      );

      context.go('/orders/${order.id}');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cartProvider = context.watch<CartProvider>();

    if (_addressController.text != cartProvider.deliveryAddress) {
      _addressController.value = TextEditingValue(
        text: cartProvider.deliveryAddress,
        selection: TextSelection.collapsed(
          offset: cartProvider.deliveryAddress.length,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/home');
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: const Text('Carrinho'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
      ),
      body: cartProvider.items.isEmpty
          ? const EmptyStateWidget(
              title: 'Seu carrinho esta vazio',
              subtitle: 'Adicione produtos para continuar.',
              icon: Icons.shopping_cart_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                ...cartProvider.items.map(_buildItemTile),
                const SizedBox(height: 14),
                _buildSummaryCard(cartProvider),
                const SizedBox(height: 14),
                _buildAddressField(cartProvider),
                const SizedBox(height: 10),
                _buildDeliveryMap(cartProvider),
                const SizedBox(height: 14),
                _buildPaymentMethodPicker(cartProvider),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Finalizar pedido',
                  isLoading: _isSubmitting,
                  icon: Icons.shopping_bag_outlined,
                  onPressed: _placeOrder,
                ),
              ],
            ),
    );
  }

  Widget _buildItemTile(CartItemModel cartItem) {
    final CartProvider cartProvider = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key('cart-item-${cartItem.product.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: const Icon(Icons.delete_outline, color: AppColors.white),
        ),
        onDismissed: (_) => cartProvider.removeItem(cartItem.product.id),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: cartItem.product.displayImage ?? '',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.gray100,
                    width: 64,
                    height: 64,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cartItem.product.name,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(cartItem.product.price),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Subtotal: ${Formatters.currency(cartItem.subtotal)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => cartProvider.updateQuantity(
                      cartItem.product.id,
                      cartItem.quantity - 1,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.gray700,
                  ),
                  Text(
                    cartItem.quantity.toString(),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => cartProvider.updateQuantity(
                      cartItem.product.id,
                      cartItem.quantity + 1,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: <Widget>[
          _buildSummaryLine(
            'Subtotal',
            Formatters.currency(cartProvider.subtotal),
          ),
          const SizedBox(height: 6),
          _buildSummaryLine(
            'Taxa de entrega',
            Formatters.currency(cartProvider.deliveryFee),
          ),
          const Divider(height: 20, color: AppColors.gray200),
          _buildSummaryLine(
            'Total',
            Formatters.currency(cartProvider.total),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: highlight ? AppColors.gray900 : AppColors.gray700,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: highlight ? AppColors.primary : AppColors.gray900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(CartProvider cartProvider) {
    return TextField(
      controller: _addressController,
      onChanged: cartProvider.setDeliveryAddress,
      decoration: InputDecoration(
        labelText: 'Endereco de entrega',
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDeliveryMap(CartProvider cartProvider) {
    final LatLng selectedPoint =
        cartProvider.deliveryLocation ?? const LatLng(-3.7319, -38.5267);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: selectedPoint,
            initialZoom: 14,
            onTap: (_, LatLng point) => cartProvider.setDeliveryLocation(point),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mercadolocal.appclient',
            ),
            MarkerLayer(
              markers: <Marker>[
                Marker(
                  point: selectedPoint,
                  width: 42,
                  height: 42,
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodPicker(CartProvider cartProvider) {
    final Map<String, String> options = <String, String>{
      'pix': 'Pix',
      'credit_card': 'Cartao de credito',
      'debit_card': 'Cartao de debito',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Forma de pagamento',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((MapEntry<String, String> entry) {
              final bool isSelected = cartProvider.paymentMethod == entry.key;
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => cartProvider.setPaymentMethod(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray300,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.white : AppColors.gray700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
