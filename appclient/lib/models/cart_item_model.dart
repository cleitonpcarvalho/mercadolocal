import 'product_model.dart';

class CartItemModel {
  const CartItemModel({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  int get storeId => product.store?.id ?? 0;

  double get subtotal => product.price * quantity;

  CartItemModel copyWith({ProductModel? product, int? quantity}) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
