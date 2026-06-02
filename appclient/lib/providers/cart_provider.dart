import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_colors.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = <CartItemModel>[];

  String _paymentMethod = 'pix';
  String _deliveryAddress = '';
  LatLng? _deliveryLocation;

  List<CartItemModel> get items => List<CartItemModel>.unmodifiable(_items);
  String get paymentMethod => _paymentMethod;
  String get deliveryAddress => _deliveryAddress;
  LatLng? get deliveryLocation => _deliveryLocation;

  int get storeId => _items.isEmpty ? 0 : _items.first.storeId;

  double get subtotal {
    return _items.fold<double>(
      0,
      (double previousValue, CartItemModel element) =>
          previousValue + element.subtotal,
    );
  }

  double get deliveryFee => _items.isEmpty ? 0 : 5.0;

  double get total => subtotal + deliveryFee;

  Future<void> addItem(BuildContext context, ProductModel product) async {
    if (_items.isNotEmpty && product.store?.id != _items.first.storeId) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.white,
            title: const Text('Loja diferente'),
            content: const Text(
              'Seu carrinho ja tem itens de outra loja. Finalize ou limpe o carrinho para continuar.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Entendi',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final int index = _items.indexWhere(
      (CartItemModel item) => item.product.id == product.id,
    );
    if (index == -1) {
      _items.add(CartItemModel(product: product, quantity: 1));
    } else {
      final CartItemModel current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + 1);
    }

    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((CartItemModel item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final int index = _items.indexWhere(
      (CartItemModel item) => item.product.id == productId,
    );
    if (index == -1) return;

    _items[index] = _items[index].copyWith(quantity: quantity);
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    _paymentMethod = value;
    notifyListeners();
  }

  void setDeliveryAddress(String value) {
    _deliveryAddress = value;
    notifyListeners();
  }

  void setDeliveryLocation(LatLng value) {
    _deliveryLocation = value;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _deliveryAddress = '';
    _deliveryLocation = null;
    _paymentMethod = 'pix';
    notifyListeners();
  }
}
